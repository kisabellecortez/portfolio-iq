library(shiny)
library(bslib)

source("database_connection.R")

source("data/dropdowns_data.R")
source("data/performance_data.R")
source("data/portfolio_overview_data.R")
source("data/portfolio_performance_data.R")
source("data/portfolio_projected_performance_data.R")

source("pages/overview.R")
source("pages/performance.R")
source("pages/projected_performance.R")

ui <- page_sidebar(
  title = "PortfolioIQ",
  
  sidebar = sidebar(
    selectInput(
      inputId = "portfolio_id",
      label = "Select Portfolio",
      choices = NULL
    ),
    
    navset_pill_list(
      id = "portfolio_pages",
      
      nav_panel(
        title = "Portfolio Overview",
        value = "overview"
      ),
      nav_panel(
        title = "Portfolio Performance",
        value = "performance"
      ),
      nav_panel(
        title = "Projected Performance",
        value = "projected_performance"
      )
    )
  ),
  
  uiOutput("page_content")
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
    selected = if (nrow(portfolios) > 0) {
      portfolios$portfolio_id[1]
    } else {
      character(0)
    }
  )
  
  selected_portfolio_id <- reactive({
    req(input$portfolio_id)
    as.integer(input$portfolio_id)
  })
  
  output$page_content <- renderUI({
    req(input$portfolio_pages)
    
    if (input$portfolio_pages == "overview") {
      portfolio_overview_ui()
    } else if (input$portfolio_pages == "performance") {
      portfolio_performance_page_ui()
    } else if (input$portfolio_pages == "projected_performance") {
      portfolio_projected_performance_page_ui()
    }
  })
  
  portfolio_overview_server(
    input,
    output,
    session,
    selected_portfolio_id
  )
  
  portfolio_performance_server(
    input,
    output,
    session,
    selected_portfolio_id
  )
  
  portfolio_projected_performance_server(
    input, 
    output, 
    session,
    selected_portfolio_id
  )
}

shinyApp(ui, server)