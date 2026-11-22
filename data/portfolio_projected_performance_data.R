simulate_portfolio_performance <- function(
    portfolio_returns,
    current_value,
    simulations = 10000
) {
  historical_returns <- na.omit(portfolio_returns$daily_return)
  
  if (length(historical_returns) < 2) {
    stop("Not enough historical returns to run simulations.")
  }
  
  if (is.na(current_value) || current_value <= 0) {
    stop("Current portfolio value must be positive.")
  }

  average_daily_return <- mean(historical_returns)
  daily_volatility <- sd(historical_returns)

  projection_periods <- data.frame(
    period = c("1M", "6M", "1Y", "2Y", "5Y"),
    trading_days = c(21, 126, 252, 504, 1260)
  )
  
  max_days <- max(projection_periods$trading_days)

  simulated_returns <- matrix(
    rnorm(
      n = max_days * simulations,
      mean = average_daily_return,
      sd = daily_volatility
    ),
    nrow = max_days,
    ncol = simulations
  )
  
  simulated_values <- apply(
    simulated_returns,
    2,
    function(returns) {
      current_value * cumprod(1 + returns)
    }
  )

  projection_results <- do.call(
    rbind,
    lapply(seq_len(nrow(projection_periods)), function(i) {
      
      days <- projection_periods$trading_days[i]
      
      values <- simulated_values[days, ]
      
      data.frame(
        period = projection_periods$period[i],
        trading_days = days,
        lower_bound = unname(quantile(values, 0.05)),
        median_value = unname(quantile(values, 0.50)),
        upper_bound = unname(quantile(values, 0.95)),
        expected_value = mean(values)
      )
    })
  )
  
  return(list(
    projections = projection_results,
    simulated_values = simulated_values,
    average_daily_return = average_daily_return,
    daily_volatility = daily_volatility
  ))
}