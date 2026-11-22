portfolio_projected_performance_page_ui <- function() {
  tagList(
    h2("Projected Performance"),
    
    card(
      plotlyOutput("projection_chart", height = "450px")
    ),
    
    uiOutput("projected_values")
  )
}

portfolio_projected_performance_server <- function(input, output, session, portfolio_id) {
  projection_data <- reactive({
    req(portfolio_id())
    
    portfolio_returns <- get_portfolio_returns(portfolio_id())
    
    portfolio_values <- get_portfolio_performance(portfolio_id()) %>%
      arrange(date)
    
    req(nrow(portfolio_returns) > 1)
    req(nrow(portfolio_values) > 0)
    
    current_value <- tail(portfolio_values$portfolio_value, 1)
    
    simulation_results <- simulate_portfolio_performance(
      portfolio_returns = portfolio_returns,
      current_value = current_value,
      simulations = 10000
    )
    
    projections <- simulation_results$projections
    simulation_values <- simulation_results$simulated_values
    
    # Prepare chart data
    projection_chart_data <- data.frame(
      day = 0:1260,
      year = (0:1260) / 252,
      
      lower_bound = c(
        current_value,
        apply(simulation_values, 1, quantile, probs = 0.05)
      ),
      
      median_value = c(
        current_value,
        apply(simulation_values, 1, median)
      ),
      
      upper_bound = c(
        current_value,
        apply(simulation_values, 1, quantile, probs = 0.95)
      )
    )
    
    return(list(
      projections = projections,
      chart_data = projection_chart_data
    ))
  })
  
  output$projection_chart <- renderPlotly({
    
    chart_data <- projection_data()$chart_data
    
    plot_ly(chart_data, x = ~year) %>%
      
      add_lines(
        y = ~lower_bound,
        name = "5th Percentile",
        line = list(dash = "dash")
      ) %>%
      
      add_lines(
        y = ~median_value,
        name = "Median",
        line = list(width = 3)
      ) %>%
      
      add_lines(
        y = ~upper_bound,
        name = "95th Percentile",
        line = list(dash = "dash")
      ) %>%
      
      layout(
        xaxis = list(
          title = "Years",
          range = c(0, 5)
        ),
        
        yaxis = list(
          title = "Projected Portfolio Value",
          tickprefix = "$",
          separatethousands = TRUE
        ),
        
        hovermode = "x unified",
        legend = list(
          orientation = "h",
          x = 0,
          y = -0.2
        )
      )
  })
  
  output$projected_values <- renderUI({
    projections <- projection_data()$projections
    
    one_year <- projections %>%
      filter(period == "1Y")
    
    five_year <- projections %>%
      filter(period == "5Y")
    
    tagList(
      layout_columns(
        card(
          h4("1-Year Projection"),
          
          layout_columns(
            div(
              h6("5th Percentile"),
              h5(scales::dollar(one_year$lower_bound))
            ),
            
            div(
              h6("Median"),
              h5(scales::dollar(one_year$median_value))
            ),
            
            div(
              h6("95th Percentile"),
              h5(scales::dollar(one_year$upper_bound))
            ),
            
            col_widths = c(4, 4, 4)
          )
        ),
        
        card(
          h4("5-Year Projection"),
          
          layout_columns(
            div(
              h6("5th Percentile"),
              h5(scales::dollar(five_year$lower_bound))
            ),
            
            div(
              h6("Median"),
              h5(scales::dollar(five_year$median_value))
            ),
            
            div(
              h6("95th Percentile"),
              h5(scales::dollar(five_year$upper_bound))
            ),
            
            col_widths = c(4, 4, 4)
          )
        ),
        
        col_widths = c(12, 12)
      )
    )
  })
}