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

df <- read_excel("data/volatility/volatility_with_stocks_20250204.xlsx")

df <- df %>% mutate(Curr = factor(Curr, levels = c("CAD", "USD")),
              Period = if_else(
                (as.Date(`Trade_Date`) >= as.Date("2013-03-11") & as.Date(`Trade_Date`) <= as.Date("2013-03-24")) |
                  (as.Date(`Trade_Date`) >= as.Date("2013-06-10") & as.Date(`Trade_Date`) <= as.Date("2013-06-23")) |
                  (as.Date(`Trade_Date`) >= as.Date("2013-09-09") & as.Date(`Trade_Date`) <= as.Date("2013-09-22")),
                1,0))
df <- df %>% filter((Trade_Date >= "2013-02-25" & Trade_Date <= "2013-03-24") |
              (Trade_Date >= "2013-05-27" & Trade_Date <= "2013-06-23") |
              (Trade_Date >= "2013-08-26" & Trade_Date <= "2013-09-22"))
              
              
model <- lm(std_return_1 ~ Curr * Period, data = df)
model_2 <- lm(std_return_1 ~ Curr * Period + `Equity Return` + Volatility + `T`,
              data = df)

# Generate publication-quality table using stargazer
stargazer(model, model_2, type = "html", out = "reports/tables/volatility_201250204.html",
          title = "Daily volatility DiD Analysis", 
          dep.var.labels = "Realized Volatility", 
          #covariate.labels = c("Group", "Period", 
          #                     "Tenor (2Y)", "Tenor (5Y)", 
          #                     "Equity Return", "Volatility", "Group * Period"),
          column.labels = c("Simple Model", "Full Model"),
          digits = 3)
  