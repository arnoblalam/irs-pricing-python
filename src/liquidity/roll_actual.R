library(tidyverse)
library(ggplot2)
library(lubridate)
library(writexl)
source("src/liquidity/roll_measure_fn.R")

# Phase 1
pre_1_usd_pretrend_1 <- read_data("data/raw/trades/USD/USD_20130128-20130208.xlsx") %>%
  process_data(min_obs = 8)

pre_1_usd_pretrend_2 <- read_data("data/raw/trades/USD/USD_20130211-20130222.xlsx") %>%
  process_data(min_obs = 8)

pre_1_usd <- read_data("data/raw/trades/USD/USD_20130223-20130310.xlsx") %>%
  process_data(min_obs = 8)

post_1_usd <- read_data("data/raw/trades/USD/USD_20130311-20130324.xlsx") %>%
  process_data(min_obs = 8)


pre_1_cad_pretrend_1 <- read_data("data/raw/trades/CAD/CAD_20130128-20130208.xlsx",
                                  currency = "CAD") %>%
  process_data(min_obs = 3)

pre_1_cad_pretrend_2 <- read_data("data/raw/trades/CAD/CAD_20130211-20130222.xlsx",
                                  currency = "CAD") %>%
  process_data(min_obs = 3)

pre_1_cad <- read_data("data/raw/trades/CAD/CAD_20130223-20130310.xlsx", 
                       currency = "CAD") %>%
  process_data(min_obs = 3)

post_1_cad <- read_data("data/raw/trades/CAD/CAD_20130311-20130324.xlsx",
                        currency = "CAD") %>%
  process_data(min_obs = 3)

# Phase 2
pre_2_usd_pretrend_1 <- read_data("data/raw/trades/USD/USD_20130428-20130510.xlsx") %>%
  process_data(min_obs = 8)

pre_2_usd_pretrend_2 <- read_data("data/raw/trades/USD/USD_20130513-20130524.xlsx") %>%
  process_data(min_obs = 8)

pre_2_usd <- read_data("data/raw/trades/USD/USD_20130526-20130609.xlsx") %>%
  process_data(min_obs = 8)

post_2_usd <- read_data("data/raw/trades/USD/USD_20130610-20130623.xlsx") %>%
  process_data(min_obs = 8)


pre_2_cad_pretrend_1 <- read_data("data/raw/trades/CAD/CAD_20130428-20130510.xlsx",
                                  currency = "CAD") %>%
  process_data(min_obs = 3)

pre_2_cad_pretrend_2 <- read_data("data/raw/trades/CAD/CAD_20130513-20130524.xlsx",
                                  currency = "CAD") %>%
  process_data(min_obs = 3)

pre_2_cad <- read_data("data/raw/trades/CAD/CAD_20130526-20130609.xlsx", 
                       currency = "CAD") %>%
  process_data(min_obs = 3)

post_2_cad <- read_data("data/raw/trades/CAD/CAD_20130610-20130623.xlsx",
                        currency = "CAD") %>%
  process_data(min_obs = 3)

# Phase 3
pre_3_usd_pretrend_1 <- read_data("data/raw/trades/USD/USD_20130729-20130809.xlsx") %>%
  process_data(min_obs = 8)

pre_3_usd_pretrend_2 <- read_data("data/raw/trades/USD/USD_20130812-20130823.xlsx") %>%
  process_data(min_obs = 8)

pre_3_usd <- read_data("data/raw/trades/USD/USD_20130824-20130908.xlsx") %>%
  process_data(min_obs = 8)

post_3_usd <- read_data("data/raw/trades/USD/USD_20130909-20130922.xlsx") %>%
  process_data(min_obs = 8)


pre_3_cad_pretrend_1 <- read_data("data/raw/trades/CAD/CAD_20130729-20130809.xlsx",
                                  currency = "CAD") %>%
  process_data(min_obs = 3)

pre_3_cad_pretrend_2 <- read_data("data/raw/trades/CAD/CAD_20130812-20130823.xlsx",
                                  currency = "CAD") %>%
  process_data(min_obs = 3)

pre_3_cad <- read_data("data/raw/trades/CAD/CAD_20130824-20130908.xlsx", 
                       currency = "CAD") %>%
  process_data(min_obs = 3)

post_3_cad <- read_data("data/raw/trades/CAD/CAD_20130909-20130922.xlsx",
                        currency = "CAD") %>%
  process_data(min_obs = 3)

combined <- 
  bind_rows(pre_1_usd_pretrend_1, pre_1_usd_pretrend_2, pre_1_cad_pretrend_1, pre_1_cad_pretrend_2, pre_1_usd, pre_1_cad, post_1_usd, post_1_cad,
            pre_2_usd_pretrend_1, pre_2_usd_pretrend_2, pre_2_cad_pretrend_1, pre_2_cad_pretrend_2, pre_2_usd, pre_2_cad, post_2_usd, post_2_cad,
            pre_3_usd_pretrend_1, pre_3_usd_pretrend_2, pre_3_cad_pretrend_1, pre_3_cad_pretrend_2, pre_3_usd, pre_3_cad, post_3_usd, post_3_cad) #%>%
  #write_csv("data/processed/liqudity/phase_1.csv")
writexl::write_xlsx(combined, "data/liquidity/Roll/USD_CAD_Roll_20250119.xlsx")

# combined_1 <- 
#   pre_1_usd %>% 
#   bind_rows(pre_1_cad, post_1_usd, post_1_cad) %>%
#   write_csv("data/processed/liqudity/phase_1.csv")
# 
# # Phase 2
# pre_2_usd <- read_data("data/raw/USD/USD_20130526-20130609.xlsx") %>%
#   process_data(min_obs = 8)
# 
# post_2_usd <- read_data("data/raw/USD/USD_20130610-20130623.xlsx") %>%
#   process_data(min_obs = 8)
# 
# pre_2_cad <- read_data("data/raw/CAD/CAD_20130526-20130609.xlsx", 
#                        currency = "CAD") %>%
#   process_data(min_obs = 3)
# 
# post_2_cad <- read_data("data/raw/CAD/CAD_20130610-20130623.xlsx",
#                         currency = "CAD") %>%
#   process_data(min_obs = 3)
# 
# combined_2 <- 
#   pre_2_usd %>% 
#   bind_rows(pre_2_cad, post_2_usd, post_2_cad) %>%
#   write_csv("data/processed/liqudity/phase_2.csv")
# 
# 
# # Phase 3
# pre_3_usd <- read_data("data/raw/USD/USD_20130824-20130908.xlsx") %>%
#   process_data(min_obs = 8)
# 
# post_3_usd <- read_data("data/raw/USD/USD_20130909-20130922.xlsx") %>%
#   process_data(min_obs = 8)
# 
# pre_3_cad <- read_data("data/raw/CAD/CAD_20130824-20130908.xlsx", 
#                        currency = "CAD") %>%
#   process_data(min_obs = 3)
# 
# post_3_cad <- read_data("data/raw/CAD/CAD_20130909-20130922.xlsx",
#                         currency = "CAD") %>%
#   process_data(min_obs = 3)
# 
# combined_3 <- 
#   pre_3_usd %>% 
#   bind_rows(pre_3_cad, post_3_usd, post_3_cad) %>%
#   write_csv("data/processed/liqudity/phase_3.csv")