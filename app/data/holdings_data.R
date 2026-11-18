library(dplyr)

holdings_data <- data.frame(
  ticker = c("AAPL", "MSFT", "NVDA", "VFV.TO", "SHOP.TO", "AMZN"),
  
  company = c(
    "Apple Inc.",
    "Microsoft Corporation",
    "NVIDIA Corporation",
    "Vanguard S&P 500 ETF",
    "Shopify Inc.",
    "Amazon.com Inc."
  ),
  
  shares = c(50, 25, 40, 100, 30, 15),
  
  current_price = c(220, 480, 150, 145, 120, 200),
  
  invested = c(8000, 10000, 6000, 5000, 7000, 2500)
) %>%
  mutate(
    market_value = shares * current_price,
    gain_loss = market_value - invested,
    return_pct = (gain_loss / invested) * 100,
    allocation = (market_value / sum(market_value)) * 100
  )