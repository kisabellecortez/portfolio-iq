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