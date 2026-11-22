calculate_total_return <- function(portfolio_returns) {
  
  portfolio_returns <- na.omit(portfolio_returns)
  
  if (length(portfolio_returns) == 0) {
    return(NA_real_)
  }
  
  total_return <- prod(1 + portfolio_returns) - 1
  
  return(total_return)
}


calculate_annualized_return <- function(portfolio_returns) {
  
  portfolio_returns <- na.omit(portfolio_returns)
  
  if (length(portfolio_returns) == 0) {
    return(NA_real_)
  }
  
  annualized_return <- prod(1 + portfolio_returns) ^
    (252 / length(portfolio_returns)) - 1
  
  return(annualized_return)
}


calculate_volatility <- function(portfolio_returns) {
  
  portfolio_returns <- na.omit(portfolio_returns)
  
  if (length(portfolio_returns) < 2) {
    return(NA_real_)
  }
  
  volatility <- sd(portfolio_returns) * sqrt(252)
  
  return(volatility)
}


calculate_sharpe_ratio <- function(portfolio_returns, risk_free_rate = 0.03) {
  
  portfolio_returns <- na.omit(portfolio_returns)
  
  if (length(portfolio_returns) < 2) {
    return(NA_real_)
  }
  
  daily_rf <- (1 + risk_free_rate) ^ (1 / 252) - 1
  
  excess_returns <- portfolio_returns - daily_rf
  
  if (sd(portfolio_returns) == 0) {
    return(NA_real_)
  }
  
  sharpe_ratio <- mean(excess_returns) / sd(portfolio_returns) * sqrt(252)
  
  return(sharpe_ratio)
}


calculate_max_drawdown <- function(portfolio_values) {
  portfolio_values <- na.omit(portfolio_values)
  
  if (length(portfolio_values) < 2 || any(portfolio_values <= 0)) {
    return(NA_real_)
  }
  
  running_peak <- cummax(portfolio_values)
  
  drawdowns <- (portfolio_values - running_peak) / running_peak
  
  return(min(drawdowns))
}


calculate_beta <- function(portfolio_returns, benchmark_returns) {
  valid_data <- complete.cases(
    portfolio_returns,
    benchmark_returns
  )
  
  portfolio_returns <- portfolio_returns[valid_data]
  benchmark_returns <- benchmark_returns[valid_data]
  
  if (length(portfolio_returns) < 2 || var(benchmark_returns) == 0) {
    return(NA_real_)
  }
  
  beta <- cov(portfolio_returns, benchmark_returns) / var(benchmark_returns)
  
  return(beta)
}


calculate_downside_deviation <- function(portfolio_returns, mar = 0) {
  portfolio_returns <- na.omit(portfolio_returns)
  
  if (length(portfolio_returns) == 0) {
    return(NA_real_)
  }
  
  downside_returns <- pmin(portfolio_returns - mar, 0)
  
  downside_deviation <- sqrt(mean(downside_returns ^ 2)) * sqrt(252)
  
  return(downside_deviation)
}


calculate_var <- function(portfolio_returns, portfolio_value, confidence_level = 0.95) {
  portfolio_returns <- na.omit(portfolio_returns)
  
  if (
    length(portfolio_returns) == 0 ||
    length(portfolio_value) != 1 ||
    is.na(portfolio_value) ||
    portfolio_value <= 0
  ) {
    return(NA_real_)
  }
  
  return_threshold <- quantile(
    portfolio_returns,
    1 - confidence_level,
    names = FALSE
  )
  
  var_percentage <- max(0, -return_threshold)
  
  var_amount <- portfolio_value * var_percentage
  
  return(var_amount)
}