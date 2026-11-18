library(scales)

portfolio_holdings_ui <- function() {
  tagList(
    uiOutput("holdings_cards")
  )
}

portfolio_holdings_server <- function(input, output, session) {
  holdings <- reactive({
    holdings_data
  })
  
  output$holdings_cards <- renderUI({
    
    data <- holdings()
    
    fluidRow(
      lapply(seq_len(nrow(data)), function(i) {
        
        holding <- data[i, ]
        
        column(
          width = 4,
          
          card(
            class = "holding-card",
            
            card_body(
              fluidRow(
                
                # Left side
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
                
                # Right side
                column(
                  width = 6,
                  
                  div(
                    class = "text-end",
                    
                    h4(
                      dollar(holding$market_value),
                      class = "mb-1"
                    ),
                    
                    span(
                      paste0(
                        ifelse(
                          holding$gain_loss >= 0,
                          "+",
                          "-"
                        ),
                        dollar(abs(holding$gain_loss)),
                        " (",
                        sprintf("%.2f", holding$return_pct),
                        "%)"
                      ),
                      
                      class = ifelse(
                        holding$gain_loss >= 0,
                        "text-success",
                        "text-danger"
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