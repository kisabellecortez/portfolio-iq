SELECT 
  price_date AS date,
  close_price AS benchmark_value
FROM benchmark_historical_prices
WHERE benchmark_id = $1
ORDER BY price_date;
