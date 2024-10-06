# Load necessary libraries
library(readxl)
library(dplyr)
library(lubridate)
library(broom)
library(stargazer)

# Helper functions
# Categorize trade time
categorize_trade_time <- function(time) {
  ifelse((hour(time) >= 8 & hour(time) < 11), 'morning',
    ifelse(hour(time) >= 11 & hour(time) < 14, 'mid day',
           ifelse(hour(time) >= 14 & hour(time) < 17, 'afternoon', 'off hours')))
}

# Define a function to check if the trade date falls within the specified periods
in_period <- function(trade_date) {
  # Define the date ranges
  periods <- data.frame(start = as.Date(c('2013-03-11', '2013-06-10', '2013-09-09')),
                        end = as.Date(c('2013-03-22', '2013-06-21', '2013-09-20')))
  
  # Check if the date falls within any of the ranges
  within_any_period <- any(apply(periods, 1, function(x) trade_date >= x[1] & trade_date <= x[2]))
  
  return(as.integer(within_any_period))
}

# Load the data
data <- read_excel('data/volatility/combined_trade_data.xlsx')

# Convert 'Effective', 'Maturity', and 'Trade Time' columns to datetime format
data$Effective <- ymd(data$Effective)
data$Maturity <- ymd(data$Maturity)
data$`Trade Time` <- ymd_hms(data$`Trade Time`)

# Add some additional columns
data$Trade_Date <- as.Date(data$`Trade Time`)

# Convert rates specified in bps to percentages
data <- data %>% 
  mutate(`Rate 1` = ifelse(`Rate 1` > 10, `Rate 1`/100, `Rate 1`))

data <- data %>% 
  mutate(trade_time_categorical = categorize_trade_time(`Trade Time`))

data$Grp <- ifelse(data$Curr == 'USD', 1,
                   ifelse(data$Curr == 'CAD', 0, -1))

# Filter and process the data
data_filtered <- data %>%
  filter(Type == 'IRS Fix-Float',
         CD == 'TR',
         `Leg 2` %in% c('USD-LIBOR-BBA', 'CAD-BA-CDOR'),
         Curr %in% c('USD', 'CAD'),
         (Effective- Trade_Date) <= 30,
         wday(`Trade Time`, week_start = 1) < 6,
         date(`Trade Time`) != mdy('09022013'),
         date(`Trade Time`) != mdy('05272013'),
         `T` %in% c('1Y', '2Y', '3Y', '4Y', '5Y', '6Y', '7Y',
                    '8Y', '9Y', '10Y', '15Y', '30Y')) %>%
  arrange(Curr, `T`, Trade_Date, `Trade Time`) %>%
  group_by(Curr, `T`, Trade_Date) %>%
  mutate(return_1 = log(`Rate 1`/lag(`Rate 1`)))

# Group by and summarize
new_data <- data_filtered %>%
  group_by(Curr, T, Trade_Date) %>%
  summarize(std_return_1 = sd(return_1, na.rm = TRUE)) %>%
  ungroup()

# Rename the column and prepare for regression
new_data$Grp <- ifelse(new_data$Curr == 'USD', 1, ifelse(new_data$Curr == 'CAD', 0, -1))
new_data$period <- sapply(new_data$Trade_Date, in_period)
new_data$interaction <- new_data$Grp * new_data$period

model <- lm(std_return_1 ~ Grp* period, data = new_data)
summary(model)

library(stargazer)
stargazer(model, type = "text",
          title = "Volatility Regression",
          align = TRUE,
          covariate.labels = c("Group", 
                               "Period",
                               "Group * Period"),
          dep.var.caption = "Dependent variable: Realized Volatility",
          dep.var.labels.include = FALSE,
          digits = 4,
          no.space = TRUE)#,
          #out = "reports/tables/volatility.txt")
