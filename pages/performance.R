portfolio_performance_page_ui <- function() {
  tagList(
    h2("Performance Overview"),
    
    uiOutput("performance_metrics_boxes"),
    
    uiOutput("benchmark_selector"),
    
    radioButtons(
      "performance_period",
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
    
    plotlyOutput("performance_chart", height = "550px"),
    
    h4("Risk Analysis"),
    
    div(
      style = "margin-bottom: 20px;",
      uiOutput("risk_analysis")
    )
  )
}

portfolio_performance_server <- function(input, output, session, portfolio_id) {
  output$benchmark_selector <- renderUI({
    
    benchmarks <- get_benchmarks()
    
    req(nrow(benchmarks) > 0)
    
    selectInput(
      "benchmark_id",
      "Compare Against",
      choices = setNames(
        as.character(benchmarks$benchmark_id),
        benchmarks$benchmark_name
      ),
      selected = as.character(benchmarks$benchmark_id[1])
    )
  })
  
  selected_benchmark_id <- reactive({
    req(input$benchmark_id)
    as.integer(input$benchmark_id)
  })
  
  output$performance_metrics_boxes <- renderUI({
    req(portfolio_id())
    
    daily_returns <- get_portfolio_returns(
      portfolio_id()
    )
    
    returns <- daily_returns$daily_return
    
    total_return <- calculate_total_return(returns)
    
    annualized_return <- calculate_annualized_return(returns)
    
    volatility <- calculate_volatility(returns)
    
    sharpe_ratio <- calculate_sharpe_ratio(returns)
    
    layout_columns(
      value_box(
        title = "Total Return",
        value = if (is.na(total_return)) {
          "N/A"
        } else {
          scales::percent(total_return, accuracy = 0.01)
        },
        primary = "primary"
      ),
      
      value_box(
        title = "Annualized Return",
        value = if (is.na(annualized_return)) {
          "N/A"
        } else {
          scales::percent(annualized_return, accuracy = 0.01)
        },
        primary = "secondary"
      ),
      
      value_box(
        title = "Volatility",
        value = if (is.na(volatility)) {
          "N/A"
        } else {
          scales::percent(volatility, accuracy = 0.01)
        },
        primary = "secondary"
      ),
      
      value_box(
        title = "Sharpe Ratio",
        value = if (is.na(sharpe_ratio)) {
          "N/A"
        } else {
          round(sharpe_ratio, 2)
        },
        primary = "secondary"
      ),
      
      col_widths = c(3, 3, 3, 3)
    )
  })
  
  portfolio_data <- reactive({
    req(portfolio_id())
    
    get_portfolio_performance(portfolio_id())
  })
  
  benchmark_data <- reactive({
    req(selected_benchmark_id())
    
    get_benchmark_performance(
      selected_benchmark_id()
    )
  })
  
  filtered_performance <- reactive({
    portfolio <- portfolio_data()
    benchmark <- benchmark_data()
    
    req(nrow(portfolio) > 0)
    req(nrow(benchmark) > 0)
    
    portfolio$date <- as.Date(portfolio$date)
    benchmark$date <- as.Date(benchmark$date)
    
    common_dates <- intersect(
      portfolio$date,
      benchmark$date
    )
    
    req(length(common_dates) > 0)
    
    portfolio <- portfolio %>%
      filter(date %in% common_dates) %>%
      arrange(date)
    
    benchmark <- benchmark %>%
      filter(date %in% common_dates) %>%
      arrange(date)
    
    end_date <- max(common_dates, na.rm = TRUE)
    
    start_date <- switch(
      input$performance_period,
      "1D" = end_date - days(1),
      "1W" = end_date - weeks(1),
      "1M" = end_date - months(1),
      "3M" = end_date - months(3),
      "6M" = end_date - months(6),
      "YTD" = floor_date(end_date, "year"),
      "1Y" = end_date - years(1),
      "ALL" = min(common_dates, na.rm = TRUE)
    )
    
    portfolio <- portfolio %>%
      filter(date >= start_date, date <= end_date) %>%
      arrange(date)
    
    benchmark <- benchmark %>%
      filter(date >= start_date, date <= end_date) %>%
      arrange(date)
    
    req(nrow(portfolio) > 0)
    req(nrow(benchmark) > 0)
    
    portfolio <- portfolio %>%
      mutate(
        performance_index =
          portfolio_value / first(portfolio_value) * 100
      )
    
    benchmark <- benchmark %>%
      mutate(
        performance_index =
          benchmark_value / first(benchmark_value) * 100
      )
    
    list(
      portfolio = portfolio,
      benchmark = benchmark
    )
  })
  
  output$performance_chart <- renderPlotly({
    data <- filtered_performance()
    
    portfolio <- data$portfolio
    benchmark <- data$benchmark
    
    plot_ly() %>%
      add_lines(
        data = portfolio,
        x = ~date,
        y = ~performance_index,
        name = "Portfolio",
        line = list(width = 2),
        hovertemplate = paste(
          "%{x|%b %d, %Y}<br>",
          "Portfolio: %{y:.2f}",
          "<extra></extra>"
        )
      ) %>%
      add_lines(
        data = benchmark,
        x = ~date,
        y = ~performance_index,
        name = "Benchmark",
        line = list(width = 2, dash = "dash"),
        hovertemplate = paste(
          "%{x|%b %d, %Y}<br>",
          "Benchmark: %{y:.2f}",
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
          showgrid = TRUE,
          separatethousands = TRUE
        ),
        margin = list(t = 40, b = 50, l = 60, r = 30),
        legend = list(
          orientation = "h",
          x = 0,
          y = 1.1
        )
      ) %>%
      config(
        responsive = TRUE
      )
  })
  
  output$risk_analysis <- renderUI({
    req(portfolio_id())
    req(selected_benchmark_id())
    
    portfolio_returns <- get_portfolio_returns(
      portfolio_id()
    )
    
    benchmark_returns <- get_benchmark_returns(
      selected_benchmark_id()
    )
    
    aligned_returns <- inner_join(
      portfolio_returns,
      benchmark_returns,
      by = "date",
      suffix = c("_portfolio", "_benchmark")
    )
    
    portfolio_values <- get_portfolio_performance(
      portfolio_id()
    )
    
    portfolio_values <- portfolio_values %>%
      arrange(date)
    
    max_drawdown <- calculate_max_drawdown(
      portfolio_values$portfolio_value
    )
    
    beta <- calculate_beta(
      aligned_returns$daily_return_portfolio,
      aligned_returns$daily_return_benchmark
    )
    
    downside_deviation <- calculate_downside_deviation(
      portfolio_returns$daily_return
    )
    
    current_portfolio_value <- tail(
      portfolio_values$portfolio_value,
      1
    )
    
    var <- calculate_var(
      portfolio_returns$daily_return,
      current_portfolio_value
    )
    
    layout_columns(
      div(
        h6("Maximum Drawdown"),
        h5(
          if (is.na(max_drawdown)) {
            "N/A"
          } else {
            scales::percent(max_drawdown, accuracy = 0.01)
          }
        )
      ),
      
      div(
        h6("Beta"),
        h5(
          if (is.na(beta)) {
            "N/A"
          } else {
            round(beta, 2)
          }
        )
      ),
      
      div(
        h6("Downside Deviation"),
        h5(
          if (is.na(downside_deviation)) {
            "N/A"
          } else {
            scales::percent(downside_deviation, accuracy = 0.01)
          }
        )
      ),
      
      div(
        h6("Value at Risk (95%)"),
        h5(
          if (is.na(var)) {
            "N/A"
          } else {
            scales::dollar(var, accuracy = 0.01)
          }
        )
      ),
      
      col_widths = c(3, 3, 3, 3)
    )
  })
}
