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