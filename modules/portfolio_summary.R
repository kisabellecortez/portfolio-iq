portfolio_summary_ui <- function() {
  layout_columns(
    value_box(
      title = "Portfolio Value",
      value = "$125,450.00",
      primary = "primary"
    ),
    value_box(
      title = "Total Invested",
      value = "$115,700.00",
      primary = "secondary"
    ),
    value_box(
      title = "Unrealized Gain/Loss",
      value = "+$9,750.00",
      primary = "success"
    ),
    value_box(
      title = "Total Holdings",
      value = "20",
      primary = "secondary"
    ),
    
    col_widths = c(3, 3, 3, 3)
  )
}