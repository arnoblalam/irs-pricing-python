library(readxl)
library(lubridate)
library(tidyverse)

data <- read_excel("data/Amihud_2_combined_with_stock.xlsx")

filtered_data <- 
  data %>%
  filter(`Num Observations` >= 5)

model <- lm(Ratio ~ Group*pd + as.factor(Tenor) + stock + volatility, 
            data = filtered_data)
