
library(shiny)
library(bslib)
library(scales)
library(dplyr)

portfolio_holdings_ui <- function() {
  tagList(
    uiOutput("holdings_cards")
  )
}

portfolio_holdings_server <- function(input, output, session, portfolio_id) {
  holdings <- reactive({
    
    req(portfolio_id())
    
    con <- connect_db()
    on.exit(disconnect_db(con))
    
    get_holdings_data(
      con,
      portfolio_id = as.integer(portfolio_id())
    )
  })
  
  output$holdings_cards <- renderUI({
    data <- holdings()
    
    if(nrow(data) == 0) {
      return(
        p("No holdings found for this portfolio.",
          class = "text-muted")
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
                      if (is.na(holding$market_value)) {
                        "Price unavailable"
                      } else {
                        dollar(holding$market_value, accuracy = 0.01)
                      },
                      class = "mb-1"
                    ),
                    
                    span(
                      if (is.na(holding$gain_loss)) {
                        "Return unavailable"
                      } else {
                        paste0(
                          ifelse(
                            holding$gain_loss >= 0,
                            "+",
                            "-"
                          ),
                          dollar(abs(holding$gain_loss), accuracy = 0.01),
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
