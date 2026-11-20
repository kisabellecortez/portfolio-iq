library(shiny)
library(bslib)

source("database_connection.R")

source("modules/portfolio_summary.R")
source("modules/portfolio_performance.R")
source("modules/portfolio_allocation.R")
source("modules/holdings.R")

source("data/portfolio_data.R")
source("data/performance_data.R")
source("data/holdings_data.R")

ui <- page_sidebar(
  title = "PortfolioIQ",
  
  sidebar = sidebar(
    selectInput(
      "portfolio_id",
      "Select Portfolio",
      choices = c("Growth Portfolio" = 1)
    )
  ),
  
  h2("Investment Overview"),
  portfolio_summary_ui(),
  
  h2("Portfolio Performance"),
  portfolio_performance_ui(),
  
  h2("Asset Allocation"),
  portfolio_allocation_ui(),
  
  h2("Holdings"),
  portfolio_holdings_ui(),
)

server <- function(input, output, session) {
  portfolio_performance_server(input, output, session)
  portfolio_allocation_server(input, output, session)
  portfolio_holdings_server(input, output, session)
}

shinyApp(ui, server)