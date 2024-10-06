library(readxl)
library(lubridate)
library(tidyverse)
library(stargazer)

data <- read_excel("data/liquidity/Roll_combined_2_with_stock.xlsx")

filtered_data <- 
  data %>%
  filter(`Num Observations` >= 5)

model <- lm(`Roll Measure` ~ Group*pd + as.factor(Tenor) + stock + volatility, 
            data = filtered_data)
stargazer(model, type = "html", out = "reports/Roll_measure.html")
