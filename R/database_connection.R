library(DBI)
library(RPostgres)
library(dotenv)

dotenv::load_dot_env()

connect_db <- function() {
  con <- dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("DB_HOST"),
    port = as.integer(Sys.getenv("DB_PORT")),
    dbname = Sys.getenv("DB_NAME"),
    user = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASSWORD")
  )
  
  return(con)
}

disconnect_db <- function(con) {
  if(!is.null(con) && DBI::dbIsValid(con)) {
    DBI::dbDisconnect(con)
  }
}