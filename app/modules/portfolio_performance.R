library(shiny)
library(plotly)
library(dplyr)
library(lubridate)

portfolio_performance_ui <- function() {
  tagList(
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
    
    plotlyOutput("performance_chart", height = "350px")
  )
}

portfolio_performance_server <- function(input, output, session) {
  filtered_performance <- reactive({
    data <- performance_data
    end_date <- max(data$date)
    start_date <- switch(
      input$performance_period,
      "1D" = end_date - days(1),
      "1W" = end_date - weeks(1),
      "1M" = end_date - months(1),
      "3M" = end_date - months(3),
      "6M" = end_date - months(6),
      "YTD" = floor_date(end_date, "year"),
      "1Y" = end_date - years(1),
      "ALL" = min(data$date)
    )
    
    data %>%
      filter(date >= start_date, date <= end_date)
  })
  
  output $performance_chart <- renderPlotly({
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
        xaxis = list(
          title = "",
          showgrid = FALSE
        ),
        yaxis = list(
          title = "",
          tickprefix = "$",
          separatethousands = TRUE
        ),
        margin = list(t = 20, b = 40, l = 60, r = 20),
        showlegend = FALSE
      )
  })
}