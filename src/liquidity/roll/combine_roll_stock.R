# Name:         combine_roll_stock.R
# Maintainer:   Arnob L. Alam (arnoblalam@gmail.com)
# Last Updated: 2025-01-21
#
# Combine Roll's measure with equity market return and volatility data

library(tidyverse)
library(readxl)
library(writexl)


# Read in S&P 500, TSX Composite, CBOE VIX and Canadian VIX (VIXI) data
spy <- read_csv("data/raw/equity_market/S&P 500 Historical Data.csv",
                col_types = cols(Date = col_date(format = "%m/%d/%Y")))
tsx <- read_csv("data/raw/equity_market/S&P_TSX Composite Historical Data.csv",
                col_types = cols(Date = col_date(format = "%m/%d/%Y")))
vix <- read_csv("data/raw/equity_market/CBOE Volatility Index Historical Data.csv",
                col_types = cols(Date = col_date(format = "%m/%d/%Y")))
vixi <- read_csv("data/raw/equity_market/S&P_TSX 60 VIX Historical Data.csv",
                 col_types = cols(Date = col_date(format = "%m/%d/%Y")))

# Add a column identifying the currency
spy <- spy %>% mutate(Curr = "USD")
vix <- vix %>% mutate(Curr = "USD")
tsx <- tsx %>% mutate(Curr = "CAD")
vixi <- vixi %>% mutate(Curr = "CAD")

# Fix some column names, convert character columns to numeric
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

# Combine the equity returns data to a single table
equity_returns <- spy %>% add_row(tsx)

# Combine the volatility data to a single table 
volatility <- vix %>% add_row(vixi)

# Merge the two tables by Trade Date and Currency
combined_df <- equity_returns %>% left_join(volatility) %>% 
  select(`Trade Date`, Curr, `Equity Return`, Volatility)

# Read in Roll's data
roll_data <- read_excel("data/liquidity/Roll/USD_CAD_Roll_20250119.xlsx")

combined_roll <- roll_data %>% 
  left_join(combined_df, by = c("Trade_Date" = "Trade Date", "Curr" = "Curr"))

write_xlsx(combined_roll, "data/liquidity/Roll/Roll_with_stocks_20250120.xlsx")
