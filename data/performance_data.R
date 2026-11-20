get_portfolio_performance <- function(portfolio_id) {
  con <- connect_db()
  
  query <- paste(
    readLines("sql/queries/portfolio_performance.sql"),
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