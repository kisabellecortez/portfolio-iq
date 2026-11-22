portfolio_overview_ui <- function() {
  tagList(
    h2("Investment Overview"),
    
    uiOutput("portfolio_summary_boxes"),
    
    radioButtons(
      "overview_performance_period",
      NULL,
      choices = c(
        "1D" = "1D",
        "1W" = "1W",
        "1M" = "1M",
        "3M" = "3M",
        "6M" = "6M",
        "YTD" = "YTD",
        "1Y" = "1Y",
        "ALL" = "ALL"
      ),
      selected = "1M",
      inline = TRUE
    ),
    
    plotlyOutput("overview_performance_chart", height = "550px"),
    
    uioutput("sector_pie"),
    
    uiOutput("security_type_pie"),
    
    h2("Holdings"),
    
    uiOutput("holdings_cards")
  )
}

portfolio_overview_server <- function(input, output, session, portfolio_id) {
  summary_data <- reactive({
    req(portfolio_id())
    
    con <- connect_db()
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    
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
  
  performance_data <- reactive({
    req(portfolio_id())
    
    get_portfolio_performance(portfolio_id())
  })
  
  filtered_performance <- reactive({
    data <- performance_data()
    
    req(nrow(data) > 0)
    
    data$date <- as.Date(data$date)
    
    end_date <- max(data$date, na.rm = TRUE)
    
    start_date <- switch(
      input$overview_performance_period,
      "1D" = end_date - days(1),
      "1W" = end_date - weeks(1),
      "1M" = end_date - months(1),
      "3M" = end_date - months(3),
      "6M" = end_date - months(6),
      "YTD" = floor_date(end_date, "year"),
      "1Y" = end_date - years(1),
      "ALL" = min(data$date, na.rm = TRUE)
    )
    
    data %>%
      filter(date >= start_date, date <= end_date) %>%
      arrange(date)
  })
  
  output$overview_performance_chart <- renderPlotly({
    data <- filtered_performance()
    
    plot_ly(
      data = data,
      x = ~date,
      y = ~portfolio_value,
      type = "scatter",
      mode = "lines",
      line = list(width = 2),
      hovertemplate = paste(
        "%{x|%b %d, %Y}<br>",
        "Portfolio Value: $%{y:,.2f}",
        "<extra></extra>"
      )
    ) %>%
      layout(
        autosize = TRUE,
        height = 550,
        xaxis = list(
          title = "",
          showgrid = FALSE
        ),
        yaxis = list(
          title = "",
          tickprefix = "$",
          separatethousands = TRUE
        ),
        margin = list(t = 40, b = 50, l = 60, r = 30),
        showlegend = FALSE
      )
  })
  
  sector_data <- reactive({
    req(portfolio_id())
    
    get_sector_allocation(portfolio_id())
  })
  
  output$sector_pie <- renderPlotly({
    data <- sector_data()
    
    plot_ly(
      data = data,
      labels = ~sector,
      values = ~allocation,
      type = "pie",
      hole = 0.45,
      textinfo = "",
      hovertemplate = paste(
        "%{label}<br>",
        "Allocation: %{percent}",
        "<extra></extra>"
      )
    ) %>%
      layout(
        showlegend = TRUE,
        margin = list(t = 20, b = 20, l = 20, r = 20)
      )
  })
  
  security_type_data <- reactive({
    req(portfolio_id())
    
    get_security_type_allocation(portfolio_id())
  })
  
  output$security_type_pie <- renderPlotly({
    data <- security_type_data()
    
    plot_ly(
      data = data,
      labels = ~security_type,
      values = ~allocation,
      type = "pie",
      hole = 0.45,
      textinfo = "",
      hovertemplate = paste(
        "%{label}<br>",
        "Allocation: %{percent}",
        "<extra></extra>"
      )
    ) %>%
      layout(
        showlegend = TRUE,
        margin = list(t = 20, b = 20, l = 20, r = 20)
      )
  })
  
  holdings <- reactive({
    req(portfolio_id())
    
    con <- connect_db()
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    
    get_holdings_data(
      con,
      portfolio_id = as.integer(portfolio_id())
    )
  })
  
  output$holdings_cards <- renderUI({
    data <- holdings()
    
    if (nrow(data) == 0) {
      return(
        p(
          "No holdings found for this portfolio.",
          class = "text-muted"
        )
      )
    }
    
    fluidRow(
      lapply(seq_len(nrow(data)), function(i) {
        
        holding <- data[i, ]
        
        column(
          width = 4,
          
          card(
            class = "holding-card",
            
            card_body(
              fluidRow(
                
                column(
                  width = 6,
                  
                  h5(strong(holding$ticker)),
                  
                  div(
                    paste(holding$shares, "shares"),
                    class = "text-muted small"
                  ),
                  
                  div(
                    paste0(
                      sprintf("%.2f", holding$allocation),
                      "% allocation"
                    ),
                    class = "text-muted small"
                  )
                ),
                
                column(
                  width = 6,
                  
                  div(
                    class = "text-end",
                    
                    h4(
                      if (is.na(holding$market_value)) {
                        "Price unavailable"
                      } else {
                        scales::dollar(
                          holding$market_value,
                          accuracy = 0.01
                        )
                      },
                      class = "mb-1"
                    ),
                    
                    span(
                      if (is.na(holding$gain_loss)) {
                        "Return unavailable"
                      } else {
                        paste0(
                          ifelse(holding$gain_loss >= 0, "+", "-"),
                          scales::dollar(
                            abs(holding$gain_loss),
                            accuracy = 0.01
                          ),
                          " (",
                          sprintf("%.2f", holding$return_pct),
                          "%)"
                        )
                      },
                      
                      class = ifelse(
                        is.na(holding$gain_loss),
                        "text-muted",
                        ifelse(
                          holding$gain_loss >= 0,
                          "text-success",
                          "text-danger"
                        )
                      ),
                      
                      style = "font-size: 13px;"
                    )
                  )
                )
              )
            )
          )
        )
      })
    )
  })
}
