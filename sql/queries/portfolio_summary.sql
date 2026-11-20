
WITH latest_prices AS (
    SELECT DISTINCT ON (security_id)
        security_id,
        adjusted_close
    FROM historical_prices
    ORDER BY security_id, price_date DESC
),

buy_costs AS (
    SELECT
        portfolio_id,
        security_id,

        SUM(
            quantity * price_per_share + COALESCE(commission, 0)
        ) / NULLIF(SUM(quantity), 0) AS average_purchase_cost

    FROM transactions
    WHERE UPPER(transaction_type) = 'BUY'
    GROUP BY portfolio_id, security_id
),

holdings_value AS (
    SELECT
        h.security_id,
        h.quantity,
        lp.adjusted_close,
        bc.average_purchase_cost,

        CASE
            WHEN s.currency = p.base_currency THEN 1::NUMERIC
            WHEN fx.exchange_rate IS NOT NULL THEN fx.exchange_rate
            WHEN fx_reverse.exchange_rate IS NOT NULL
                THEN 1::NUMERIC / fx_reverse.exchange_rate
            ELSE NULL
        END AS exchange_rate

    FROM portfolio_holdings h

    JOIN portfolios p
        ON p.portfolio_id = h.portfolio_id

    JOIN securities s
        ON s.security_id = h.security_id

    LEFT JOIN latest_prices lp
        ON lp.security_id = h.security_id

    LEFT JOIN buy_costs bc
        ON bc.portfolio_id = h.portfolio_id
        AND bc.security_id = h.security_id

    LEFT JOIN exchange_rates fx
        ON fx.base_currency = s.currency
        AND fx.quote_currency = p.base_currency

    LEFT JOIN exchange_rates fx_reverse
        ON fx_reverse.base_currency = p.base_currency
        AND fx_reverse.quote_currency = s.currency

    WHERE h.portfolio_id = $1
      AND h.quantity > 0
)

SELECT
    COALESCE(
        SUM(quantity * adjusted_close * exchange_rate),
        0
    ) AS portfolio_value,

    COALESCE(
        SUM(quantity * average_purchase_cost * exchange_rate),
        0
    ) AS total_invested,

    COALESCE(
        SUM(
            quantity * (adjusted_close - average_purchase_cost)
            * exchange_rate
        ),
        0
    ) AS unrealized_gain_loss,

    COUNT(DISTINCT security_id) AS total_holdings

FROM holdings_value;
