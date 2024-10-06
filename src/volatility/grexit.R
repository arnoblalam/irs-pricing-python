# Load necessary libraries
library(readxl)
library(dplyr)
library(lubridate)
library(ggplot2)
library(stargazer)

# Load data (as done before, adjust file paths accordingly)
cad_data <- read_excel("data/GREXIT/CAD_20150601-20150731.xlsx")
usd_data_1 <- read_excel("data/GREXIT/USD_20150601-20150607.xlsx")
usd_data_2 <- read_excel("data/GREXIT/USD_20150608-20150614.xlsx")
usd_data_3 <- read_excel("data/GREXIT/USD_20150615-20150621.xlsx")
usd_data_4 <- read_excel("data/GREXIT/USD_20150622-20150628.xlsx")
usd_data_5 <- read_excel("data/GREXIT/USD_20150629-20150705.xlsx")
usd_data_6 <- read_excel("data/GREXIT/USD_20150706-20150712.xlsx")
usd_data_7 <- read_excel("data/GREXIT/USD_20150713-20150719.xlsx")
usd_data_8 <- read_excel("data/GREXIT/USD_20150720-20150726.xlsx")
usd_data_9 <- read_excel("data/GREXIT/USD_20150727-20150731.xlsx")

# Combine USD data
usd_data <- bind_rows(usd_data_1, usd_data_2, usd_data_3, usd_data_4, usd_data_5, usd_data_6, usd_data_7, usd_data_8, usd_data_9)

# Parse Trade Date and calculate daily returns/volatility
cad_data$TradeDate <- as.Date(cad_data$`Trade Time`, format = "%m/%d/%Y")
usd_data$TradeDate <- as.Date(usd_data$`Trade Time`, format = "%m/%d/%Y")

# Filter out relevant columns (Rate 1, Notional, and Trade Date)
cad_filtered <- cad_data %>%
  select(TradeDate, `Rate 1`, `Not.`) %>%
  filter(!is.na(`Rate 1`))

usd_filtered <- usd_data %>%
  select(TradeDate, `Rate 1`, `Not.`) %>%
  filter(!is.na(`Rate 1`))

# Group by date and calculate daily mean rate
cad_daily <- cad_filtered %>%
  group_by(TradeDate) %>%
  summarise(DailyRate = mean(`Rate 1`))

usd_daily <- usd_filtered %>%
  group_by(TradeDate) %>%
  summarise(DailyRate = mean(`Rate 1`))

# Calculate daily percentage change (volatility proxy)
cad_daily <- cad_daily %>%
  mutate(Return = (DailyRate / lag(DailyRate)) - 1) %>%
  na.omit()

usd_daily <- usd_daily %>%
  mutate(Return = (DailyRate / lag(DailyRate)) - 1) %>%
  na.omit()

# Create a combined data frame for analysis
combined_data <- bind_rows(
  cad_daily %>% mutate(Market = "CAD"),
  usd_daily %>% mutate(Market = "USD")
)

# Define pre and post periods based on the treatment date
treatment_date <- as.Date("2015-06-26")
combined_data <- combined_data %>%
  mutate(PostPeriod = ifelse(TradeDate > treatment_date, 1, 0),
         Treatment = ifelse(Market == "USD", 1, 0))

# Difference-in-differences regression model
did_model <- lm(Return ~ PostPeriod * Treatment, data = combined_data)

# Output the result using stargazer for HTML tables
stargazer(did_model, type = "html", 
          title = "Difference-in-Differences Analysis of Volatility During GREXIT",
          dep.var.labels = "Volatility (Daily Return)",
          covariate.labels = c("Post Period", "USD Market", "Post Period x USD Market"),
          out = "reports/tables/GREXIT.html")

# The results will be saved in 'diff_in_diff_results.html'
