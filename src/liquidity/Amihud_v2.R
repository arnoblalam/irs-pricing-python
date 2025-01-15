library(tidyverse)
library(readxl)
library(lubridate)

apply_default_filters <- function(df, currency = "USD") {
  variable_rate_index <-
    case_when(
      currency == "USD" ~ "USD-LIBOR-BBA",
      currency == "GBP" ~ "GBP-LIBOR-BBA",
      currency == "CHF" ~ "CHF-LIBOR-BBA",
      currency == "CAD" ~ "CAD-BA-CDOR"
    )
  if(is_character(df$Effective)) {
    df_ <- df  %>%
      mutate(
        Effective = mdy(Effective),
        Maturity = mdy(Maturity),
        `Trade Time` = mdy_hms(`Trade Time`, tz = "America/New_York")
      )
  }
  else {
    df_ <- df
  }
  df_  %>%
    mutate(`Rate 1` = if_else(`Rate 1` > 10, `Rate 1`/100, `Rate 1`)) %>%
    filter(
      Type == "IRS Fix-Float",
      CD == "TR",
      `Leg 1` == "FIXED",
      `Leg 2` == variable_rate_index,
      Curr == currency,
      `PF 1` != "1T",
      `PF 2` != "1T",
      is.na(`Othr Pmnt`),
      Not. >= 0.5E6,
      is.na(`Rate 2`),
      `Rate 1` > 0,
      difftime(Effective, `Trade Time`, units = "days") < 31,
      !(wday(`Trade Time`, label = TRUE) %in% c("Sun", "Sat"))
    )
}

calculate_amihud_measure <- function(df) {
  tenors <- c("2Y", "5Y", "10Y")
  df %>%
    group_by(Tenor = T, `Trade Date` = date(`Trade Time`)) %>%
    mutate(`Log Rate 1` = log(`Rate 1`),
           `Not. in Millions` = Not. / 1E6) %>%
    filter(Tenor %in% tenors) %>%
    mutate(Return = abs(`Log Rate 1` - lag(`Log Rate 1`)) * 100) %>%
    mutate(`Price Imapct` = Return / `Not. in Millions`) %>%
    summarize(Amihud = mean(`Price Imapct`, na.rm = TRUE),
              Curr = last(Curr))
}

# Load in the data
usd_pretrend_pre_1 <- read_excel("data/raw/trades/USD/USD_20130128-20130208.xlsx")
usd_pretrend_post_1 <- read_excel("data/raw/trades/USD/USD_20130211-20130222.xlsx")
usd_pre_1 <- read_excel("data/raw/trades/USD/USD_20130223-20130310.xlsx")
usd_post_1 <- read_excel("data/raw/trades/USD/USD_20130311-20130324.xlsx")

usd_pretrend_pre_2 <- read_excel("data/raw/trades/USD/USD_20130428-20130510.xlsx")
usd_pretrend_post_2 <- read_excel("data/raw/trades/USD/USD_20130513-20130524.xlsx")
usd_pre_2 <- read_excel("data/raw/trades/USD/USD_20130526-20130609.xlsx")
usd_post_2 <- read_excel("data/raw/trades/USD/USD_20130610-20130623.xlsx")

usd_pretrend_pre_3 <- read_excel("data/raw/trades/USD/USD_20130729-20130809.xlsx")
usd_pretrend_post_3 <- read_excel("data/raw/trades/USD/USD_20130812-20130823.xlsx")
usd_pre_3 <- read_excel("data/raw/trades/USD/USD_20130824-20130908.xlsx")
usd_post_3 <- read_excel("data/raw/trades/USD/USD_20130909-20130922.xlsx")

cad_pretrend_pre_1 <- read_excel("data/raw/trades/CAD/CAD_20130128-20130208.xlsx")
cad_pretrend_post_1 <- read_excel("data/raw/trades/CAD/CAD_20130211-20130222.xlsx")
cad_pre_1 <- read_excel("data/raw/trades/CAD/CAD_20130223-20130310.xlsx")
cad_post_1 <- read_excel("data/raw/trades/CAD/CAD_20130311-20130324.xlsx")

cad_pretrend_pre_2 <- read_excel("data/raw/trades/CAD/CAD_20130428-20130510.xlsx")
cad_pretrend_post_2 <- read_excel("data/raw/trades/CAD/CAD_20130513-20130524.xlsx")
cad_pre_2 <- read_excel("data/raw/trades/CAD/CAD_20130526-20130609.xlsx")
cad_post_2 <- read_excel("data/raw/trades/CAD/CAD_20130610-20130623.xlsx")

cad_pretrend_pre_3 <- read_excel("data/raw/trades/CAD/CAD_20130729-20130809.xlsx")
cad_pretrend_post_3 <- read_excel("data/raw/trades/CAD/CAD_20130812-20130823.xlsx")
cad_pre_3 <- read_excel("data/raw/trades/CAD/CAD_20130824-20130908.xlsx")
cad_post_3 <- read_excel("data/raw/trades/CAD/CAD_20130909-20130922.xlsx")

usd_frames <- list(
  usd_pretrend_pre_1, usd_pretrend_post_1, usd_pre_1, usd_post_1,
  usd_pretrend_pre_2, usd_pretrend_post_2, usd_pre_2, usd_post_2,
  usd_pretrend_pre_3, usd_pretrend_post_3, usd_pre_3, usd_post_3
)

cad_frames <- list(
  cad_pretrend_pre_1, cad_pretrend_post_1, cad_pre_1, cad_post_1,
  cad_pretrend_pre_2, cad_pretrend_post_2, cad_pre_2, cad_post_2,
  cad_pretrend_pre_3, cad_pretrend_post_3, cad_pre_3, cad_post_3
)

do_thing <- function(df, currency = "USD") {
  df %>% apply_default_filters(currency = currency) %>% calculate_amihud_measure()
}

usd_res <- lapply(usd_frames, do_thing)
cad_res <- lapply(cad_frames, do_thing, currency = "CAD")

usd_export <- do.call(bind_rows, usd_res)
cad_export <- do.call(bind_rows, cad_res)

my_export <- bind_rows(usd_export, cad_export)
xlsx::write.xlsx(my_export %>% ungroup(), "data/liquidity/Amihud/Amihd_Measure_2025_14_01.xlsx")
