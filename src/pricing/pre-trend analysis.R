# Name:         pre-trend analysis.R
# Maintainer:   Arnob L. Alam (arnoblalam@gmail.com)
# Last Updated: 2025-01-09
#
# Analyzes the ten trading days before the phase 1 study period to
# establish that parallel trends hold.

# Load required libraries
library(tidyverse)
library(sandwich)
library(lmtest)
library(stargazer)


# Helper functions

# Fix the names of Capped and Notional columns
fix_names <- function(df) {
  df %>% rename(Capped = `...11`,
                Notional = Not.,
                `Trade Delay` = `Time from Trade to Effective`)
}

# Apply some common filters
filter_df <- function(df) {
  # Filter out dates
  dates_to_exclude <- as.Date(c(
    "2013-01-27",
    "2013-02-02",
    "2013-02-03",
    "2013-02-09",
    "2013-02-10",
    "2013-02-18"
  ))
  df %>% 
    filter(!(as.Date(`Trade Time`) %in% dates_to_exclude)) %>%
  # Filter out zero notional
    filter(Notional > 0) %>%
    filter(`Trade Delay` <= 92)
}

# Mutate some columns
fix_columns <- function(df) {
  df %>%
    mutate(
      Capped = if_else(Capped == "+", 1, 0, missing = 0),
      Clr = if_else(Clr == "C",1, 0),
      SEF = if_else(SEF == "ON", 1, 0),
      `Trade Date` = as.Date(`Trade Time`),
      Curr = factor(Curr, levels = c("CAD", "USD")),
      `Log Notional` = log(Notional))
}

# 2-year contracts
df_2y <- readxl::read_excel("data/pricing/two year contracts pre-trend.xlsx") %>%
  fix_names() %>%
  filter_df() %>%
  fix_columns()

# 5-year contracts
df_5y <- readxl::read_excel("data/pricing/five year contract pretrend.xlsx") %>%
  fix_names() %>%
  filter_df() %>%
  fix_columns()

df_10y <- readxl::read_excel("data/pricing/ten year contracts pre-trend.xlsx") %>%
  fix_names() %>%
  filter_df() %>%
  fix_columns()


model_2y <- lm(`Rate 1` ~ Curr * `Trade Date` + `Log Notional` + Clr + Capped, 
            data = df_2y)
model_5y <- lm(`Rate 1` ~ Curr * `Trade Date` + `Log Notional` + Clr + Capped, 
               data = df_5y)
model_10y <- lm(`Rate 1` ~ Curr * `Trade Date` + `Log Notional` + Clr + Capped, 
                data = df_10y)

clustered_se_2y <- vcovCL(model_2y, cluster = ~ `Trade Date`)
res_2y <- coeftest(model_2y, vcov = clustered_se_2y)

clustered_se_5y <- vcovCL(model_5y, cluster = ~ `Trade Date`)
res_5y <- coeftest(model_5y, vcov = clustered_se_5y)

clustered_se_10y <- vcovCL(model_10y, cluster = ~ `Trade Date`)
res_10y <- coeftest(model_10y, vcov = clustered_se_10y)

stargazer::stargazer(res_2y, res_5y, res_10y, 
                     type = "html",
                     out = "reports/tables/pre-trend.html",
                     title = "Pre-trend Analysis",
                     column.labels = c("2-year contracts", "5-year contracts", "10-year contracts"),
                     dep.var.labels = c("Fixed Rate"),
                     nobs = TRUE,
                     omit.table.layout = "n",
                     model.numbers = FALSE,
                     report = c("vcs"))
