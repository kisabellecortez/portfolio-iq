performance_metrics_ui <- function() {
  uiOutput("performance_metrics_boxes")
}

performance_metrics_server <- function(input, output, session, portfolio_id) {
  output$performance_metrics_boxes <- renderUI({
    
    daily_returns <- get_daily_returns(portfolio_id())
    
    performance_metrics_data <- get_performance_metrics(
      daily_returns$daily_return
    )
    
    total_return <- performance_metrics_data$total_return
    annualized_return <- performance_metrics_data$annualized_return
    volatility <- performance_metrics_data$volatility
    sharpe_ratio <- performance_metrics_data$sharpe_ratio
    
    layout_columns(
      value_box(
        title = "Total Return",
        value = tags$span(
          if (is.na(total_return)) {
            "N/A"
          } else {
            scales::percent(total_return, accuracy = 0.01)
          },
          style = paste0(
            "color: ",
            if (!is.na(total_return) && total_return >= 0) "#198754" else "#dc3545",
            " !important;"
          )
        ),
        primary = "primary"
      ),
      value_box(
        title = "Annualized Return",
        value = scales::percent(annualized_return, accuracy = 0.01),
        primary = "secondary"
      ),
      value_box(
        title = "Volatility",
        value = scales::percent(volatility, accuracy = 0.01),
        primary = "secondary"
      ),
      value_box(
        title = "Sharpe Ratio",
        value = round(sharpe_ratio, 2),
        primary = "secondary"
      ),
      col_widths = c(3, 3, 3, 3)
    )
  })
}