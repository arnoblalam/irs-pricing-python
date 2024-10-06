# Install the stargazer package if you don't have it
# install.packages("stargazer")

# Load necessary libraries
library(readxl)
library(dplyr)
library(lmtest)
library(sandwich)
library(stargazer)

# Load the data
file_path <- "data/liquidity/relative bid ask spread/Bid-Ask.xlsx"
df <- read_excel(file_path, sheet = "For_regression")

# Create treatment and post_treatment variables
df <- df %>%
  mutate(
    treatment = ifelse(Currency == "USD", 1, 0),
    post_treatment = Period
  )

# Fit the Difference-in-Differences model
model <- lm(`Relative Spread` ~ treatment * post_treatment + factor(Tenor), data = df)


# Generate publication-quality table using stargazer
stargazer(model, type = "html", out = "reports/tables/realized bid ask spread.html",
          title = "Relative Bid-Ask Spread DiD Analysis", 
          dep.var.labels = "Relative Spread", 
          covariate.labels = c("Group", "Period", 
                               "Tenor (2Y)", "Tenor (5Y)", "Group*Period"),
          digits = 3)
