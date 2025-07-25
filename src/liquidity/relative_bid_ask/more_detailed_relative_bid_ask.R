# Load libraries (no changes needed)
library(readxl)
library(dplyr)
library(lmtest)
library(sandwich)
library(stargazer)

# Load data (no changes needed)
file_path <- "data/liquidity/relative bid ask spread/Relative_Bid_Ask_Spread_with_stocks_20250121.xlsx"
df <- read_excel(file_path)

# Data preparation (with clearer labeling of treatment)
df <- df %>%
  mutate(
    Curr = factor(Curr, levels = c("CAD", "USD")),
    Group = if_else(Curr == "USD", 1, 0), # Treatment group indicator
    Period = if_else(
      (as.Date(`Trade Date`) >= as.Date("2013-03-11") & as.Date(`Trade Date`) <= as.Date("2013-03-24")) |
        (as.Date(`Trade Date`) >= as.Date("2013-06-10") & as.Date(`Trade Date`) <= as.Date("2013-06-23")) |
        (as.Date(`Trade Date`) >= as.Date("2013-09-09") & as.Date(`Trade Date`) <= as.Date("2013-09-22")),
      1, 0
    ),
    Tenor = factor(Tenor) # Ensure Tenor is categorical
  )

# Triple interaction model (Group × Period × Tenor)
model_interaction <- lm(`Relative Spread` ~ Group * Period * Tenor + `Equity Return` + Volatility, data = df)

# Robust standard errors (HC1)
hc1_se_interaction <- coeftest(model_interaction, vcov = vcovHC(model_interaction, type = "HC1"))[, 2]

# Display results using stargazer
stargazer(model_interaction,
          type = "html",
          out = "reports/tables/kara_question.html",
          title = "Triple Interaction DiD Analysis (Group × Period × Tenor)",
          se = list(hc1_se_interaction),
          dep.var.labels = "Relative Spread",
          digits = 3,
          notes = "Robust (HC1) standard errors in parentheses.")
