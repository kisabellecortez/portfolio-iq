get_portfolios <- function() {
  con <- connect_db()
  
  query <- "
    SELECT 
      portfolio_id,
      portfolio_name
    FROM portfolios
    ORDER BY portfolio_name;
  "
  
  result <- dbGetQuery(con, query)
  
  dbDisconnect(con)
  
  return(result)
}

get_benchmarks <- function() {
  con <- connect_db()
  
  query <- "
    SELECT
      benchmark_id,
      benchmark_name
    FROM benchmarks
    ORDER BY benchmark_name;
  "
  
  result <- dbGetQuery(con, query)
  
  dbDisconnect(con)
  
  return(result)
}