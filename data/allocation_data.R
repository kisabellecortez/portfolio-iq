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