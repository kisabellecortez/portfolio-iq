WITH holding_values AS (
  SELECT
    COALESCE(s.sector, 'Unclassified') AS sector,
    h.quantity * hp.close *
    CASE
        WHEN s.currency = p.base_currency THEN 1
        WHEN fx.exchange_rate IS NOT NULL THEN fx.exchange_rate
        WHEN fx_reverse.exchange_rate IS NOT NULL
            THEN 1.0 / fx_reverse.exchange_rate
        ELSE NULL
    END AS market_value

  FROM portfolio_holdings h

  JOIN portfolios p
    ON h.portfolio_id = p.portfolio_id

  JOIN securities s
    ON h.security_id = s.security_id

  JOIN LATERAL (
    SELECT close
    FROM historical_prices
    WHERE security_id = s.security_id
    ORDER BY price_date DESC
    LIMIT 1
  ) hp ON TRUE

  LEFT JOIN exchange_rates fx
    ON fx.base_currency = s.currency
    AND fx.quote_currency = p.base_currency

  LEFT JOIN exchange_rates fx_reverse
    ON fx_reverse.base_currency = p.base_currency
    AND fx_reverse.quote_currency = s.currency

  WHERE h.portfolio_id = $1
)

SELECT
  sector,
  SUM(market_value) AS market_value,

  ROUND(
    100.0 * SUM(market_value) /
    NULLIF(SUM(SUM(market_value)) OVER (), 0),
    2
  ) AS allocation

FROM holding_values
GROUP BY sector
ORDER BY market_value DESC;
