# Name:         combine_amihud_stock.R
# Maintainer:   Arnob L. Alam (arnoblalam@gmail.com)
# Last Updated: 2025-01-21
#
# Combine Amihud's Illiquidity Measure with equity market volatility and returns
# data.

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

# Join the volatility and returns dfs into one df, matching by date and currency
combined_df <- equity_returns %>% left_join(volatility) %>% 
  select(`Trade Date`, Curr, `Equity Return`, Volatility)

# Read in Amihud illiquidity Data
amihud_data <- read_excel("data/liquidity/Amihud/Amihud_Measure_20250119.xlsx")

# Combine the Amihud illiqudity data with equity market data 
combined_am <- amihud_data %>% left_join(combined_df)

# Save to file
write_xlsx(combined_am, "data/liquidity/Amihud/Amihud_with_stocks_20250121.xlsx")
