WITH dates AS (
    SELECT DISTINCT price_date AS date
    FROM historical_prices
    WHERE price_date >= CURRENT_DATE - INTERVAL '1 year'
),

holdings_over_time AS (
    SELECT
        d.date,
        t.security_id,
        SUM(
            CASE
                WHEN LOWER(t.transaction_type) = 'buy' THEN t.quantity
                WHEN LOWER(t.transaction_type) = 'sell' THEN -t.quantity
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
)

SELECT
    date,
    portfolio_value
FROM daily_values
ORDER BY date;
