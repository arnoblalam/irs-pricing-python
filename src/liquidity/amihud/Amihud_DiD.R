library(readxl)
library(lubridate)
library(tidyverse)
library(stargazer)

data <- read_excel("data/liquidity/Amihd_2_combined.xlsx")

filtered_data <- 
  data %>%
  filter(`Num Observations` >= 5)

model_1 <- lm(Ratio ~ Group*pd + as.factor(Tenor), data = filtered_data)


data_2 <- read_excel("data/liquidity/Amihud_2_combined_with_stock.xlsx")

filtered_data_2 <- 
  data_2 %>%
  filter(`Num Observations` >= 5)
model_2 <- lm(Ratio ~ Group*pd + as.factor(Tenor) + stock + volatility, 
            data = filtered_data_2)

stargazer(model_1, model_2, type = "text", out = "reports/Amihud_measure.txt")
