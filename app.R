library(shiny)
library(bslib)

source("database_connection.R")

source("data/allocation_data.R")
source("data/holdings_data.R")
source("data/performance_data.R")
source("data/portfolios.R")
source("data/portfolio_summary.R")

source("modules/portfolio_holdings.R")
source("modules/portfolio_allocation.R")
source("modules/portfolio_performance.R")
source("modules/portfolio_summary.R")

ui <- page_sidebar(
  title = "PortfolioIQ",
  
  sidebar = sidebar(
    selectInput(
      "portfolio_id",
      "Select Portfolio",
      choices = character(0)
    )
  ),
  
  h2("Investment Overview"),
  portfolio_summary_ui(),
  
  h2("Portfolio Performance"),
  portfolio_performance_ui(),
  
  h2("Asset Allocation"),
  portfolio_allocation_ui(),
  
  h2("Holdings"),
  portfolio_holdings_ui()
)

server <- function(input, output, session) {
  portfolios <- get_portfolios()
  
  updateSelectInput(
    session,
    "portfolio_id",
    choices = setNames(
      portfolios$portfolio_id,
      portfolios$portfolio_name
    ),
    selected = portfolios$portfolio_id[1]
  )
  
  selected_portfolio_id <- reactive({
    as.integer(input$portfolio_id)
  })
  
  portfolio_summary_server(
    input, output, session, selected_portfolio_id
  )
  
  portfolio_performance_server(
    input, output, session, selected_portfolio_id
  )
  
  portfolio_allocation_server(
    input, output, session, selected_portfolio_id
  )
  
  portfolio_holdings_server(
    input, output, session, selected_portfolio_id
  )
}

shinyApp(ui, server)
