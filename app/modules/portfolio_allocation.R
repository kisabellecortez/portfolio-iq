library(shiny)
library(plotly)

portfolio_allocation_ui <- function() {
  fluidRow(
    column(
      width = 6,
      h3("Sector Distribution"),
      plotlyOutput("sector_pie")
    ),
    column(
      width = 6,
      h3("Security Type Distribution"),
      plotlyOutput("security_type_pie")
    )
  )
}

portfolio_allocation_server <- function(input, output, session) {
  output$sector_pie <- renderPlotly({
    plot_ly(
      data = sector_data,
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
  
  output$security_type_pie <- renderPlotly({
    plot_ly(
      data = security_type_data,
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
}