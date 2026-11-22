library(DBI)
library(dplyr)

get_portfolio_summary <- function(con, portfolio_id) {
  query <- paste(
    readLines("sql/queries/portfolio_summary.sql"),
    collapse = "\n"
  )
  
  DBI::dbGetQuery(
    con,
    query,
    params = list(portfolio_id)
  )
}

get_sector_allocation <- function(portfolio_id) {
  con <- connect_db()
  
  query <- paste(
    readLines("sql/queries/sector_distribution.sql"),
    collapse = "\n"
  )
  
  result <- dbGetQuery(
    con,
    query,
    params = list(portfolio_id)
  )
  
  dbDisconnect(con)
  
  return(result)
}

get_security_type_allocation <- function(portfolio_id) {
  con <- connect_db()
  
  query <- paste(
    readLines("sql/queries/security_type_distribution.sql"),
    collapse = "\n"
  )
  
  result <- dbGetQuery(
    con,
    query,
    params = list(portfolio_id)
  )
  
  dbDisconnect(con)
  
  return(result)
}

get_holdings_data <- function(con, portfolio_id) {
  query <- paste(
    readLines("sql/queries/holdings_data.sql"),
    collapse="\n"
  )
  
  holdings_data <- dbGetQuery(
    con, 
    query,
    params = list(portfolio_id)
  )
  
  holdings_data <- holdings_data %>%
    mutate(
      market_value = shares * current_price,
      gain_loss = market_value - invested,
      return_pct = ifelse(
        invested > 0,
        (gain_loss / invested) * 100,
        NA_real_
      ),
      allocation = ifelse(
        sum(market_value, na.rm = TRUE) > 0,
        market_value / sum(market_value, na.rm = TRUE) * 100,
        0
      )
    )
  
  return(holdings_data)
}