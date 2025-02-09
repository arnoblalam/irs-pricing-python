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
  rename(`Trade_Date` = Date, `Equity Return` = `Change %`) %>% 
  select(`Trade_Date`, `Equity Return`, Curr) %>%
  mutate(`Equity Return` = as.numeric(sub("%", "", `Equity Return`))/100)
vix <- vix %>% 
  rename(`Trade_Date` = Date, Volatility = Price) %>% 
  select(`Trade_Date`, Volatility, Curr)
tsx <- tsx %>% 
  rename(`Trade_Date` = Date, `Equity Return` = `Change %`) %>% 
  select(`Trade_Date`, `Equity Return`, Curr) %>%
  mutate(`Equity Return` = as.numeric(sub("%", "", `Equity Return`))/100)
vixi <- vixi %>% 
  rename(`Trade_Date` = Date, Volatility= Price) %>% 
  select(`Trade_Date`, Volatility, Curr)

# Combine the equity returns to one df
equity_returns <- spy %>% add_row(tsx)

# Combine the volatility to one df
volatility <- vix %>% add_row(vixi)

# Merge the two tables by Trade Date and Currency
combined_df <- equity_returns %>% 
  left_join(volatility) %>% 
  select(`Trade_Date`, Curr, `Equity Return`, Volatility)

vol_data <- read_excel("data/volatility/irs_fix_float_volatility_20250121.xlsx")

vol_data <- vol_data %>% select(`Trade_Date` = Trade_Date, `std_return_1`, 
                                Curr = Curr, `T`)

rf <- vol_data %>% left_join(combined_df)

write_xlsx(rf, 
           "data/volatility/volatility_with_stocks_20250204.xlsx")
