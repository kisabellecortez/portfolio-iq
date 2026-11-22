get_portfolio_returns <- function(portfolio_id) {
  con <- connect_db()
  
  query <- readLines(
    "sql/queries/portfolio_returns.sql",
    warn = FALSE
  )
  
  portfolio_returns <- dbGetQuery(
    con,
    paste(query, collapse = "\n"),
    params = list(portfolio_id)
  )
  
  dbDisconnect(con)
  
  return(portfolio_returns)
}

get_portfolio_performance <- function(portfolio_id) {
  con <- connect_db()
  
  query <- paste(
    readLines("sql/queries/portfolio_performance.sql")
  )
  
  portfolio_performance <- dbGetQuery(
    con,
    paste(query, collapse = "\n"),
    params = list(portfolio_id)
  )
  
  dbDisconnect(con)
  
  return(portfolio_performance)
}

get_benchmark_returns <- function(benchmark_id) {
  con <- connect_db()
  
  on.exit(dbDisconnect(con))
  
  query <- paste(
    readLines("sql/queries/benchmark_returns.sql", warn = FALSE),
    collapse = "\n"
  )
  
  result <- dbGetQuery(
    con,
    query,
    params = list(as.integer(benchmark_id))
  )
  
  return(result)
}

get_benchmark_performance <- function(benchmark_id) {
  con <- connect_db()
  
  on.exit(dbDisconnect(con))
  
  query <- paste(
    readLines("sql/queries/benchmark_performance.sql", warn = FALSE),
    collapse = "\n"
  )
  
  result <- dbGetQuery(
    con,
    query,
    params = list(as.integer(benchmark_id))
  )
  
  return(result)
}