#!/usr/bin/env Rscript

# Name: DiD.R
# Last Updated: 2023-06-16
# Maintainer: Arnob L. Alam (arnoblalam@gmail.com)
#
# Description: This script performs a difference-in-differences (DID) regression analysis for
# the effect of central clearing mandates on interest rate swaps pricing.  It has two models
# - a basic model with no controls and an advanced model with additional control variables.
# This version of the script also includes separate DiD regressions for each phase and plots
# and uses the log ntionals as a control variable.

# Load necessary packages
library(tidyverse)
library(readxl)
library(stargazer)
library(stringr)
library(lubridate)
library(ggplot2)
library(hrbrthemes)

# Read the data from the Excel file
data <- read_excel("data/pricing/USD_CAD_combined_placebo.xlsx",
                   col_types = c("text", "date", "text",
                                 "numeric", "text", "text", "date",
                                 "date", "numeric", "text", "numeric",
                                 "text", "text", "numeric", "numeric",
                                 "text", "text", "text", "date", "text",
                                 "numeric", "text", "text", "text",
                                 "text", "text", "numeric", "numeric",
                                 "text", "text", "date", "numeric",
                                 "numeric"))

# Convert the 'Capped', 'SEF', Trade Day and Trade Hour variables to factors
data$Capped <- as.factor(data$Capped)
data$SEF <- as.factor(data$SEF)
data$`Day Name` <- factor(data$`Day Name`, levels = c("Wednesday",
                                                      "Monday",
                                                      "Tuesday",
                                                      "Thursday",
                                                      "Friday",
                                                      "Saturday",
                                                      "Sunday"))
data$`Trade Hour Categorical` <- factor(data$`Trade Hour Categorical`,
                                        levels = c("Mid Day",
                                                   "Morning",
                                                   "Afternoon",
                                                   "Off Hours"))

# Convert T to numeric
data$Tenure <- as.numeric(str_sub(data$T, end = -2))
# Convert notional to log notional
data$Ln_notional <- log(data$Not.)
# Convert the 'Group', 'Phase', and 'Period' variables to factors
data$Group <- as.factor(data$Group)
data$Phase <- as.factor(data$Phase)
data$Period <- as.factor(data$Period)

bound_L <- -50
bound_H <- 50
data_2 <- data %>% filter((Difference < bound_L) | (Difference > bound_H))
data <- data %>% filter(Difference >= bound_L) %>% filter(Difference <= bound_H)

did_model <- lm(
  Difference ~ Group * Period, 
  data = data)

summary(did_model)

did_model_advanced <- lm(
  Difference ~ Group * Period + Tenure + Ln_notional + Capped +
  `Trade Hour Categorical` + `Day Name`,
  data = data)

summary(did_model_advanced)


# Create the summary table with both the basic and advanced DID
# regression models
stargazer(did_model, did_model_advanced, type = "text",
          title = "Difference-in-Differences Regression Results",
          align = TRUE,
          column.labels = c("Basic Model", "Advanced Model"),
          covariate.labels = c("Group", 
                               "Period",
                               "Tenor",
                               "Log Notional", 
                               "Capped", 
                               "Morning Session", 
                               "Afternoon Session", 
                               "Off Hours",
                               "Monday",
                               "Tuesday",
                               "Thursday",
                               "Friday",
                               "Group * Period"),
          dep.var.caption = "Dependent variable: Difference",
          dep.var.labels.include = FALSE,
          digits = 4,
          no.space = TRUE)

# Save the LaTeX output to a file
summary_table <- stargazer(did_model, did_model_advanced, type = "text",
                           title = "Difference-in-Differences Regression Results",
                           align = TRUE,
                           column.labels = c("Basic Model", "Advanced Model"),
                           covariate.labels = c("Group", "Period", "Group * Period",
                                                "Maturity", "Not.", "Capped", "SEF", "Trade Hour"),
                           dep.var.caption = "Dependent variable: Difference",
                           dep.var.labels.include = FALSE,
                           digits = 4,
                           no.space = TRUE,
                           out = "reports/tables/filtered_did_placebo.txt")

# Run separate DiD for each phase: simple model
phase_1_model <- lm(
  Difference ~ Group * Period, 
  data = data %>% filter(Phase == "Phase 1"))

phase_2_model <- lm(
  Difference ~ Group * Period, 
  data = data %>% filter(Phase == "Phase 2"))

phase_3_model <- lm(
  Difference ~ Group * Period, 
  data = data %>% filter(Phase == "Phase 3"))

stargazer(phase_1_model, phase_2_model, phase_3_model, 
          type = "text",
          align = TRUE,
          column.labels = c(
            "Phase 1", 
            "Phase 2", 
            "Phase 3"),
          covariate.labels = c(
            "Group",
            "Period",
            "Group * Period"),
          title = "By Phase Results: Simple Model")

# Run separate DiD for each phase: adv model
phase_1_model_adv <- lm(
  Difference ~ Group * Period + Tenure + Ln_notional + Capped +
  `Trade Hour Categorical` + `Day Name`, 
  data = data %>% filter(Phase == "Phase 1"))

phase_2_model_adv <- lm(
  Difference ~ Group * Period + Tenure + Ln_notional + Capped +
  `Trade Hour Categorical` + `Day Name`, 
  data = data %>% filter(Phase == "Phase 2"))

phase_3_model_adv <- lm(
  Difference ~ Group * Period + Tenure + Ln_notional + Capped +
  `Trade Hour Categorical` + `Day Name`,
  data = data %>% filter(Phase == "Phase 3"))

stargazer(phase_1_model_adv, phase_2_model_adv, phase_3_model_adv, 
          type = "text",
          align = TRUE,
          column.labels = c("Phase 1", "Phase 2", "Phase 3"),
          covariate.labels = c(
            "Group",
            "Period",
            "Tenor",
            "Notional",
            "Capped",
            "Morning Session",
            "Afternoon Session",
            "Off Hours",
            "Monday",
            "Tuesday",
            "Thursday",
            "Friday",
            "Group * Period"),
          title = "By Phase Results: Advanced Model")