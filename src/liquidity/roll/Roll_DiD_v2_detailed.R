df <- read_excel("data/liquidity/Roll/Roll_with_stocks_20250120.xlsx")

df <- df %>% mutate(Curr = factor(Curr, levels = c("CAD", "USD")),
              Period = if_else(
                (as.Date(`Trade_Date`) >= as.Date("2013-03-11") & as.Date(`Trade_Date`) <= as.Date("2013-03-24")) |
                  (as.Date(`Trade_Date`) >= as.Date("2013-06-10") & as.Date(`Trade_Date`) <= as.Date("2013-06-23")) |
                  (as.Date(`Trade_Date`) >= as.Date("2013-09-09") & as.Date(`Trade_Date`) <= as.Date("2013-09-22")),
                1,0))

model <- lm(roll ~ Curr * Period, data = df)
model_2 <- lm(roll ~ Curr * Period * tenor + `Equity Return` + Volatility,
              data = df)

# Generate publication-quality table using stargazer
stargazer(model, model_2, type = "html", 
          out = "reports/tables/roll_20250720.html",
          title = "Roll's Measure DiD Analysis", 
          dep.var.labels = "Roll's Measure", 
          covariate.labels = c("Group", "Period", 
                               "Tenor (2Y)", "Tenor (5Y)", 
                               "Equity Return", "Volatility", "Group * Period"),
          column.labels = c("Simple Model", "Full Model"),
          digits = 3)
