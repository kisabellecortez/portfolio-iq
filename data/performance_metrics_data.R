
get_performance_metrics <- function(daily_returns, risk_free_rate = 0.03) {
  
  daily_returns <- na.omit(daily_returns)
  
  total_return <- calculate_total_return(daily_returns)
  
  annualized_return <- calculate_annualized_return(daily_returns)
  
  volatility <- calculate_volatility(daily_returns)
  
  sharpe_ratio <- calculate_sharpe_ratio(
    daily_returns,
    risk_free_rate
  )
  
  performance_metrics_data <- list(
    total_return = total_return,
    annualized_return = annualized_return,
    volatility = volatility,
    sharpe_ratio = sharpe_ratio
  )
  
  return(performance_metrics_data)
}


get_daily_returns <- function(portfolio_id) {
  con <- connect_db()
  
  query <- readLines(
    "sql/queries/daily_returns.sql",
    warn = FALSE
  )
  
  daily_data <- dbGetQuery(
    con,
    paste(query, collapse = "\n"),
    params = list(portfolio_id)
  )
  
  dbDisconnect(con)
  
  return(daily_data)
}


calculate_total_return <- function(daily_returns) {
  
  daily_returns <- na.omit(daily_returns)
  
  if (length(daily_returns) == 0) {
    return(NA_real_)
  }
  
  total_return <- prod(1 + daily_returns) - 1
  
  return(total_return)
}


calculate_annualized_return <- function(daily_returns) {
  
  daily_returns <- na.omit(daily_returns)
  
  if (length(daily_returns) == 0) {
    return(NA_real_)
  }
  
  annualized_return <- prod(1 + daily_returns) ^
    (252 / length(daily_returns)) - 1
  
  return(annualized_return)
}


calculate_volatility <- function(daily_returns) {
  
  daily_returns <- na.omit(daily_returns)
  
  if (length(daily_returns) < 2) {
    return(NA_real_)
  }
  
  volatility <- sd(daily_returns) * sqrt(252)
  
  return(volatility)
}


calculate_sharpe_ratio <- function(daily_returns, risk_free_rate = 0.03) {
  
  daily_returns <- na.omit(daily_returns)
  
  if (length(daily_returns) < 2) {
    return(NA_real_)
  }
  
  daily_rf <- (1 + risk_free_rate) ^ (1 / 252) - 1
  
  excess_returns <- daily_returns - daily_rf
  
  if (sd(daily_returns) == 0) {
    return(NA_real_)
  }
  
  sharpe_ratio <- mean(excess_returns) / sd(daily_returns) * sqrt(252)
  
  return(sharpe_ratio)
}
