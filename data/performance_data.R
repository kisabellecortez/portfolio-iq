library(dplyr)
library(lubridate)

set.seed(42)

performance_data <- data.frame(
  date = seq(
    Sys.Date() - 365,
    Sys.Date(),
    by = "day"
  )
) %>%
  mutate(
    portfolio_value = 100000 * cumprod(
      1 + rnorm(n(), mean = 0.0003, sd = 0.008)
    )
  )