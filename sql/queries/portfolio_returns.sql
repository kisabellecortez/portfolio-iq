WITH first_transaction AS (
    SELECT MIN(transaction_date)::date AS start_date
    FROM transactions
    WHERE portfolio_id = $1
      AND transaction_type IN ('BUY', 'SELL')
),

dates AS (
    SELECT DISTINCT price_date AS date
    FROM historical_prices
    WHERE price_date >= (
        SELECT start_date
        FROM first_transaction
    )
      AND price_date <= CURRENT_DATE
),

holdings_over_time AS (
    SELECT
        d.date,
        t.security_id,

        SUM(
            CASE
                WHEN t.transaction_type = 'BUY' THEN t.quantity
                WHEN t.transaction_type = 'SELL' THEN -t.quantity
                ELSE 0
            END
        ) AS quantity

    FROM dates d
    JOIN transactions t
        ON t.portfolio_id = $1
        AND t.transaction_date::date <= d.date

    GROUP BY d.date, t.security_id
),

daily_values AS (
    SELECT
        h.date,

        SUM(
            h.quantity * hp.adjusted_close *
            CASE
                WHEN s.currency = p.base_currency THEN 1
                WHEN fx.exchange_rate IS NOT NULL THEN fx.exchange_rate
                WHEN fx_reverse.exchange_rate IS NOT NULL
                    THEN 1.0 / fx_reverse.exchange_rate
                ELSE NULL
            END
        ) AS portfolio_value

    FROM holdings_over_time h

    JOIN portfolios p
        ON p.portfolio_id = $1

    JOIN securities s
        ON s.security_id = h.security_id

    JOIN LATERAL (
        SELECT adjusted_close
        FROM historical_prices
        WHERE security_id = h.security_id
          AND price_date <= h.date
        ORDER BY price_date DESC
        LIMIT 1
    ) hp ON TRUE

    LEFT JOIN exchange_rates fx
        ON fx.base_currency = s.currency
        AND fx.quote_currency = p.base_currency

    LEFT JOIN exchange_rates fx_reverse
        ON fx_reverse.base_currency = p.base_currency
        AND fx_reverse.quote_currency = s.currency

    WHERE h.quantity > 0

    GROUP BY h.date
),

daily_returns AS (
    SELECT
        date,
        portfolio_value,

        LAG(portfolio_value) OVER (
            ORDER BY date
        ) AS previous_value

    FROM daily_values
)

SELECT
    date,
    portfolio_value,
    previous_value,

    CASE
        WHEN previous_value > 0
            THEN (portfolio_value - previous_value) / previous_value
        ELSE NULL
    END AS daily_return

FROM daily_returns
ORDER BY date;
