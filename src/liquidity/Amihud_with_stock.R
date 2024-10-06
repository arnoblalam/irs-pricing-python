library(readxl)
library(lubridate)
library(tidyverse)
library(stargazer)

data <- read_excel("data/liquidity/Amihud_2_combined_with_stock.xlsx")

filtered_data <- 
  data %>%
  filter(`Num Observations` >= 5)

model <- lm(Ratio ~ Group*pd + as.factor(Tenor) + stock + volatility, 
            data = filtered_data)
stargazer(model, type = "html", out = "reports/Amihud_measure.html")
