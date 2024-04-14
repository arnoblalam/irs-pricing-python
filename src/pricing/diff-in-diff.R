#!/usr/bin/env Rscript

# Name: diff-in-diff.R
# Last Updated: 2023-05-06
# Maintainer: Arnob L. Alam (arnoblalam@gmail.com)

# Description: This script performs a difference-in-differences (DID) regression analysis for
# the effect of central clearing mandates on interest rate swaps pricing.  It has two models
# - a basic model with no controls and an advanced model with additional control variables.

# Load necessary packages
library(tidyverse)

# Read the data from the CSV file
data <- read.csv("data.csv")

# Convert the 'Group', 'Phase', and 'Period' variables to factors
data$Group <- as.factor(data$Group)
data$Phase <- as.factor(data$Phase)
data$Period <- as.factor(data$Period)

# Create a new variable for the hour of the day when the trade occurred
data$TradeHour <- as.numeric(format(as.POSIXct(data$Trade.Time, format = "%m/%d/%Y %H:%M:%S"), "%H"))

# Convert the 'Capped' and 'SEF' variables to factors
data$Capped <- as.factor(data$Capped)
data$SEF <- as.factor(data$SEF)

# Run the DID regression with control variables
did_model_advanced <- lm(Difference ~ Group * Period + Maturity + Not. + Capped + SEF + TradeHour, data = data)

# Display the regression results
summary(did_model_advanced)

# Load the stargazer package
library(stargazer)

# Create the summary table with both the basic and advanced DID regression models
stargazer(did_model, did_model_advanced, type = "text",
          title = "Difference-in-Differences Regression Results",
          align = TRUE,
          column.labels = c("Basic Model", "Advanced Model"),
          covariate.labels = c("Group", "Period", "Group * Period",
                               "Maturity", "Not.", "Capped", "SEF", "Trade Hour"),
          dep.var.caption = "Dependent variable: Difference",
          dep.var.labels.include = FALSE,
          digits = 4,
          no.space = TRUE)

# Save the LaTeX output to a file
summary_table <- stargazer(did_model, did_model_advanced, type = "latex",
                           title = "Difference-in-Differences Regression Results",
                           align = TRUE,
                           column.labels = c("Basic Model", "Advanced Model"),
                           covariate.labels = c("Group", "Period", "Group * Period",
                                                "Maturity", "Not.", "Capped", "SEF", "Trade Hour"),
                           dep.var.caption = "Dependent variable: Difference",
                           dep.var.labels.include = FALSE,
                           digits = 4,
                           no.space = TRUE)

cat(summary_table, file = "summary_table.tex")

