WITH transaction_summary AS (
  SELECT 
    security_id,
    
    SUM(
      CASE 
        WHEN transaction_type = 'BUY' THEN quantity
        WHEN transaction_type = 'SELL' THEN -quantity
        ELSE 0
      END
    ) AS shares,
    
    SUM(
      CASE 
        WHEN transaction_type = 'BUY' THEN quantity * price_per_share + commission
        ELSE 0
      END 
    ) AS total_buy_cost,
    
    SUM(
      CASE
        WHEN transaction_type = 'BUY' THEN quantity
        ELSE 0
      END
    ) AS total_shares_bought
    
    FROM transactions
    WHERE portfolio_id = $1
    GROUP BY security_id
),

latest_prices AS (
  SELECT DISTINCT ON (security_id)
    security_id,
    close AS current_price
  FROM historical_prices
  ORDER BY security_id, price_date DESC
)

SELECT
  s.ticker,
  s.company_name AS company,
  ts.shares,
  lp.current_price,
  
  CASE 
    WHEN ts.total_shares_bought > 0 THEN (ts.total_buy_cost / ts.total_shares_bought) * ts.shares
    ELSE 0
  END AS invested

FROM transaction_summary ts
JOIN securities s
  ON s.security_id = ts.security_id
LEFT JOIN latest_prices lp
  ON lp.security_id = ts.security_id
WHERE ts.shares > 0
ORDER BY s.ticker;