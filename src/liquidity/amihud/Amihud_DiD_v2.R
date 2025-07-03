# Name:         Amihud_DiD.R
# Maintainer:   Arnob L. Alam (arnoblalam@gmail.com)
# Last Updated: 2025-01-21
#
# Using newly created data (with additional filtering), run a 
# Difference-in-Differences model for the impact of clearing on
# Roll's measure of illiqudity.

library(tidyverse)
library(readxl)
library(stargazer)

df <- read_excel("data/liquidity/Amihud/Amihud_with_stocks_20250121.xlsx")

df <- df %>% mutate(Curr = factor(Curr, levels = c("CAD", "USD")),
              Period = if_else(
                (as.Date(`Trade Date`) >= as.Date("2013-03-11") & as.Date(`Trade Date`) <= as.Date("2013-03-24")) |
                  (as.Date(`Trade Date`) >= as.Date("2013-06-10") & as.Date(`Trade Date`) <= as.Date("2013-06-23")) |
                  (as.Date(`Trade Date`) >= as.Date("2013-09-09") & as.Date(`Trade Date`) <= as.Date("2013-09-22")),
                1,0))

model <- lm(Amihud ~ Curr * Period, data = df)
model_2 <- lm(Amihud ~ Curr * Period + Tenor + `Equity Return` + Volatility,
              data = df)

# Generate publication-quality table using stargazer
stargazer(model, model_2, type = "html", out = "reports/tables/Amihud_201250120.html",
          title = "Amihud Measure DiD Analysis", 
          dep.var.labels = "Amihud Illiquidity Measure", 
          covariate.labels = c("Group", "Period", 
                               "Tenor (2Y)", "Tenor (5Y)", 
                               "Equity Return", "Volatility", "Group * Period"),
          column.labels = c("Simple Model", "Full Model"),
          digits = 3)
  