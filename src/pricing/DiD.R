#!/usr/bin/env Rscript

# Name: DiD.R
# Last Updated: 2024-04-10
# Maintainer: Arnob L. Alam (arnoblalam@gmail.com)
#
# Description: This script performs a difference-in-differences (DID) 
# regression analysis for the effect of central clearing mandates on interest 
# rate swaps pricing.  It has two models  - a basic model with no controls and 
# an advanced model with additional control variables. This version of the 
# script also includes separate DiD regressions for each phase and plots
# and uses the log ntionals as a control variable.

# Load necessary packages
library(tidyverse)
library(readxl)
library(stargazer)
library(stringr) 

# Read the data from the Excel file
data <- read_excel("data/pricing/USD_CAD_combined.xlsx", 
                   col_types = c("text", "date", "text", 
                                 "numeric", "text", "text", "date", 
                                 "date", "numeric", "text", "numeric", 
                                 "text", "text", "numeric", "numeric", 
                                 "text", "text", "text", "date", "text", 
                                 "numeric", "text", "text", "text", 
                                 "text", "text", "numeric", "numeric", 
                                 "text", "text", "date", "numeric", 
                                 "numeric"))
bound_L <- -50
bound_H <- 50
data_2 <- data %>% filter((Difference < bound_L) | (Difference > bound_H))
data <- data %>% filter(Difference >= bound_L) %>% 
  filter(Difference <= bound_H)


# Convert the 'Group', 'Phase', and 'Period' variables to factors
data$Group <- as.factor(data$Group)
data$Phase <- as.factor(data$Phase)
data$Period <- as.factor(data$Period)

# Convert the 'Capped', 'SEF', Trade Day and Trade Hour variables to factors
data$Capped <- as.factor(data$Capped)
data$SEF <- as.factor(data$SEF)
data$Phase <- as.factor(data$Phase)
data$`Day Name` <- factor(data$`Day Name`, levels = c("Wednesday", 
                                                      "Monday",
                                                      "Tuesday",
                                                      "Thursday",
                                                      "Friday",
                                                      "Saturday",
                                                      "Sunday"))
data$`Trade Hour Categorical` <- factor(data$`Trade Hour Categorical`, 
                                        levels = c("Mid-Day", 
                                                   "Morning", 
                                                   "Afternoon", 
                                                   "Off Hours"))

# Convert T to numeric
data$Tenure <- as.numeric(str_sub(data$T, end=-2))
#data$`T` <- as.numeric(data$`T`)

# Convert file date to factor
# data$`File Date` <- factor(data$`File Date`)

# Convert notional to log notional
data$Ln_notional <- log(data$Not.)

did_model <- lm(
  Difference ~ Group * Period, 
  data = data)

summary(did_model)

did_model_advanced <- lm(
  Difference ~ Group * Period + Phase + Tenure + Ln_notional + Capped + 
    `Trade Hour Categorical` + `Day Name`,
  data = data)

summary(did_model_advanced)


# Create the summary table with both the basic and advanced DID regression models
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
          no.space = TRUE,
          out = "reports/tables/per_phase_did_basic.txt")

# Save the LaTeX output to a file
stargazer(did_model, did_model_advanced, type = "html",
                           title = "Difference-in-Differences Regression Results",
                           align = TRUE,
                           column.labels = c("Basic Model", "Advanced Model"),
                           covariate.labels = c("Group", "Period", "Group * Period",
                                                "Maturity", "Not.", "Capped", "SEF", "Trade Hour"),
                           dep.var.caption = "Dependent variable: Difference",
                           dep.var.labels.include = FALSE,
                           digits = 4,
                           no.space = TRUE,
                           out = "reports/tables/TABLE DiD (all phases).html")

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
  Difference ~ Group * Period + Tenure + Ln_notional + Capped + `Trade Hour Categorical` + `Day Name`, 
  data = data %>% filter(Phase == "Phase 1"))

phase_2_model_adv <- lm(
  Difference ~ Group * Period + Tenure + Ln_notional + Capped + `Trade Hour Categorical` + `Day Name`, 
  data = data %>% filter(Phase == "Phase 2"))

phase_3_model_adv <- lm(
  Difference ~ Group * Period + Tenure + Ln_notional + Capped + `Trade Hour Categorical` + `Day Name`, 
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
          title = "By Phase Results: Advanced Model",
          out = "reports/tables/per_phase_did.txt")

# Plots
# Group the data and get daily medians
grouped <- data %>% 
  group_by(`File Date`, Curr, Phase) %>%
  summarise(Difference = median(Difference, na.rm = TRUE),
            n = n())

lims = c(-125, 25)
shp = 21
strk = 2

# Plot trend for phase 1
ggplot(data = grouped %>% filter(Phase == "Phase 1"), 
       aes(y = Difference, x= `File Date`, color = Curr)) +
  geom_point(shape = shp, stroke = strk) +
  scale_y_continuous(limits = lims) +
  ggtitle("Phase 1 trend") +
  xlab("Date") +
  ylab("Premium (bps)") +
  ggthemes::theme_economist()

# Plot trend of phase 2
ggplot(data = grouped %>% filter(Phase == "Phase 2"), 
       aes(y = Difference, x= `File Date`, color = Curr)) +
  geom_point(shape = shp, stroke = strk) +
  scale_y_continuous(limits = lims) +
  ggtitle("Phase 2 trend") +
  xlab("Date") +
  ylab("Premium (bps)") +
  ggthemes::theme_economist()

# Plot trend for phase 3
ggplot(data = grouped %>% filter(Phase == "Phase 3"), 
       aes(y = Difference, x= `File Date`, color = Curr)) +
  geom_point(shape = shp, stroke = strk) +
  scale_y_continuous(limits = lims) +
  ggtitle("Phase 3 trend") +
  xlab("Date") +
  ylab("Premium (bps)") +
  ggthemes::theme_economist()

# Try another plotting style

# Phase 1
ggplot(data = data %>% filter(Phase == "Phase 1"), 
       aes(y = Difference, 
           x = strftime(`File Date`, "%m/%d"),
           fill = Curr)) +
  geom_boxplot(outlier.shape = NA) +
  scale_y_continuous(limits = c(-50, 50))

# Phase 2
ggplot(data = data %>% filter(Phase == "Phase 2"), 
       aes(y = Difference, 
           x = strftime(`File Date`, "%m/%d"),
           fill = Curr)) +
  geom_boxplot(outlier.shape = NA) +
  scale_y_continuous(limits = c(-50, 50))

# Phase 3
ggplot(data = data %>% filter(Phase == "Phase 3"), 
       aes(y = Difference, 
           x = strftime(`File Date`, "%m/%d"),
           fill = Curr)) +
  geom_boxplot(outlier.shape = NA) +
  scale_y_continuous(limits = c(-50, 50))
