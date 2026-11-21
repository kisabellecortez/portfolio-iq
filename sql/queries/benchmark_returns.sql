WITH benchmark_prices AS (
  SELECT 
    price_date,
    close_price,
    LAG(close_price) OVER (
      ORDER BY price_date
    ) AS previous_close
    FROM benchmark_historical_prices
    WHERE benchmark_id = $1
)

SELECT 
  price_date,
  (close_price / previous_close) - 1 AS daily_return
FROM benchmark_prices
WHERE previous_close IS NOT NULL
ORDER BY price_date;