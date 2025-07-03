# Name:         combine_relative_stock.R
# Maintainer:   Arnob L. Alam (arnoblalam@gmail.com)
# Last Updated: 2025-21-01
#
# Combine the relative bid-ask spread data with equity market returns and 
# volatatility data

library(tidyverse)
library(readxl)
library(writexl)

# Read in the data
spy <- read_csv("data/raw/equity_market/S&P 500 Historical Data.csv",
                col_types = cols(Date = col_date(format = "%m/%d/%Y")))
tsx <- read_csv("data/raw/equity_market/S&P_TSX Composite Historical Data.csv",
                col_types = cols(Date = col_date(format = "%m/%d/%Y")))
vix <- read_csv("data/raw/equity_market/CBOE Volatility Index Historical Data.csv",
                col_types = cols(Date = col_date(format = "%m/%d/%Y")))
vixi <- read_csv("data/raw/equity_market/S&P_TSX 60 VIX Historical Data.csv",
                 col_types = cols(Date = col_date(format = "%m/%d/%Y")))


# Add a column called currency
spy <- spy %>% mutate(Curr = "USD")
vix <- vix %>% mutate(Curr = "USD")
tsx <- tsx %>% mutate(Curr = "CAD")
vixi <- vixi %>% mutate(Curr = "CAD")

# Fix some column names, convert some columns from character to numeric
spy <- spy %>% 
  rename(`Trade Date` = Date, `Equity Return` = `Change %`) %>% 
  select(`Trade Date`, `Equity Return`, Curr) %>%
  mutate(`Equity Return` = as.numeric(sub("%", "", `Equity Return`))/100)
vix <- vix %>% rename(`Trade Date` = Date, Volatility = Price) %>% 
  select(`Trade Date`, Volatility, Curr)
tsx <- tsx %>% rename(`Trade Date` = Date, `Equity Return` = `Change %`) %>% 
  select(`Trade Date`, `Equity Return`, Curr) %>%
  mutate(`Equity Return` = as.numeric(sub("%", "", `Equity Return`))/100)
vixi <- vixi %>% rename(`Trade Date` = Date, Volatility= Price) %>% 
  select(`Trade Date`, Volatility, Curr)

# Combine the equity returns to one df
equity_returns <- spy %>% add_row(tsx)

# Combine the volatility to one df
volatility <- vix %>% add_row(vixi)

# Merge the two tables by Trade Date and Currency
combined_df <- equity_returns %>% left_join(volatility) %>% 
  select(`Trade Date`, Curr, `Equity Return`, Volatility)

rel_data <- read_excel("data/liquidity/relative bid ask spread/Bid-Ask.xlsx",
                       sheet = "For_regression")

rel_data <- rel_data %>% select(`Trade Date` = Date, `Relative Spread`, 
                                Curr = Currency, Tenor)

rf <- rel_data %>% left_join(combined_df)

write_xlsx(rf, 
           "data/liquidity/relative bid ask spread//Relative_Bid_Ask_Spread_with_stocks_20250121.xlsx")
