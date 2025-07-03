# Install the stargazer package if you don't have it
# install.packages("stargazer")

# Load necessary libraries
library(readxl)
library(dplyr)
#library(lmtest)
#library(sandwich)
library(stargazer)

# Load the data
file_path <- "data/liquidity/relative bid ask spread/Relative_Bid_Ask_Spread_with_stocks_20250121.xlsx"
df <- read_excel(file_path)

# Create treatment and post_treatment variables
df <- df %>% mutate(Curr = factor(Curr, levels = c("CAD", "USD")),
                    Period = if_else(
                      (as.Date(`Trade Date`) >= as.Date("2013-03-11") & as.Date(`Trade Date`) <= as.Date("2013-03-24")) |
                        (as.Date(`Trade Date`) >= as.Date("2013-06-10") & as.Date(`Trade Date`) <= as.Date("2013-06-23")) |
                        (as.Date(`Trade Date`) >= as.Date("2013-09-09") & as.Date(`Trade Date`) <= as.Date("2013-09-22")),
                      1,0))

# Fit the Difference-in-Differences model
model <- lm(`Relative Spread` ~ Curr * Period, data = df)
model_2 <- lm(`Relative Spread` ~ Curr * Period + Tenor + `Equity Return` + 
                Volatility, data = df)


# Generate publication-quality table using stargazer
stargazer(model, model_2, type = "html", 
          out = "reports/tables/realized_bid_ask spread_20250119.html",
          title = "Relative Bid-Ask Spread DiD Analysis", 
          dep.var.labels = "Relative Spread", 
          covariate.labels = c("Group", "Period", 
                               "Tenor (2Y)", "Tenor (5Y)", "Equity Return",
                               "Volatility", "Group*Period"),
          column.labels = c("Simple Model", "Full Model"),
          digits = 3)
