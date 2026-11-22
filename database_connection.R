library(DBI)
library(RPostgres)
library(dotenv)

dotenv::load_dot_env()

connect_db <- function() {
  
  db_host <- Sys.getenv("PGHOST", "localhost")
  db_port <- as.integer(Sys.getenv("PGPORT", "5434"))
  db_name <- Sys.getenv("PGDATABASE", "portfolioiq")
  db_user <- Sys.getenv("PGUSER", "portfolioiq_admin")
  db_password <- Sys.getenv("PGPASSWORD", "")
  
  con <- dbConnect(
    RPostgres::Postgres(),
    host = db_host,
    port = db_port,
    dbname = db_name,
    user = db_user,
    password = db_password
  )
  
  return(con)
}
