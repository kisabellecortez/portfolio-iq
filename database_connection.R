library(DBI)
library(RPostgres)
library(dotenv)

dotenv::load_dot_env

connect_db <- function() {
  con <- dbConnect(
    RPostgres::Postgres(),
    dbname = Sys.getenv("DB_NAME"),
    host = Sys.getenv("DB_HOST"),
    port = Sys.getenv("DB_PORT"),
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