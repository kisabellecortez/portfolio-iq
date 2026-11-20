portfolio_summary_ui <- function() {
  uiOutput("portfolio_summary_boxes")
}

portfolio_summary_server <- function(input, output, session, portfolio_id) {
  summary_data <- reactive({
    req(portfolio_id())
    
    con <- connect_db()
    on.exit(disconnect_db(con))
    
    get_portfolio_summary(
      con,
      portfolio_id = as.integer(portfolio_id())
    )
  })
  
  output$portfolio_summary_boxes <- renderUI({
    data <- summary_data()
    
    req(nrow(data) > 0)
    
    gain_loss <- data$unrealized_gain_loss
    
    layout_columns(
      value_box(
        title = "Portfolio Value",
        value = scales::dollar(data$portfolio_value, accuracy = 0.01),
        primary = "primary"
      ),
      
      value_box(
        title = "Total Invested",
        value = scales::dollar(data$total_invested, accuracy = 0.01),
        primary = "secondary"
      ),
      
      value_box(
        title = "Unrealized Gain/Loss",
        value = tags$span(
          paste0(
            if (gain_loss >= 0) "+" else "-",
            scales::dollar(abs(gain_loss), accuracy = 0.01)
          ),
          style = paste0(
            "color: ",
            if (gain_loss >= 0) "#198754" else "#dc3545",
            " !important;"
          )
        ),
        primary = "secondary"
      ),
      value_box(
        title = "Total Holdings",
        value = data$total_holdings,
        primary = "secondary"
      ),
      col_widths = c(3, 3, 3, 3)
    )
  })
}