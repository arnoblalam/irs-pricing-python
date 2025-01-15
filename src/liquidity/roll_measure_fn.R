# Name:         roll_measure_fn.R
# Maintainer:   Arnob L. Alam (arnoblalam@gmail.com)
# Last Updated: 2025-01-03
#
# A small helper function to calculate Roll's estimator for the bid-ask spread


#' Calculate the roll measure
#'
#' @param x A numeric vector of prices
#' @param logs Whether to take the logarithm of the price vector
#'
#' @return a numeric vector of length 1, either Roll's estimator o r 0 if cov
#' was not negative
#' @export
#'
#' @examples
#' roll_measure(rnorm(100))
roll_measure <- function(x, logs = FALSE) {
  if (logs == TRUE)
    x <- log(x)
  dx <- diff(x, 1)
  cov_dx <- cov(dx[-1], dx[-length(dx)])
  ifelse(cov_dx < 0, 2 * sqrt(-cov_dx), 0)
}

#' Read and return filtered data
#'
#' @param filename the xlsx file with trade data
#' @param currency the currency of the data
#'
#' @return
#' @export
#'
#' @examples
read_data <- function(filename, currency = "USD") {
  var_rate_index <-
    switch(
      currency,
      USD = "USD-LIBOR-BBA",
      CAD = "CAD-BA-CDOR",
      GBP = "GBP-LIBOR-BBA",
      CHF = "CHF-LIBOR-BBA"
    )
  df <- readxl::read_excel(filename)
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
  df_ %>%
    rename("Capped" = `...11`, Notional = Not.) %>%
    mutate(
      Clr = if_else(Clr == "C", 1, 0, missing = 0),
      SEF = if_else(SEF == "ON", 1, 0, missing = 0),
      Capped = if_else(Capped == "+", 1, 0, missing = 0)
    ) %>%
    filter(
      Type == "IRS Fix-Float",
      CD == "TR",
      `Leg 1` == "FIXED",
      `Leg 2` == var_rate_index,
      Curr == currency,
      `PF 1` != "1T",
      `PF 2` != "1T",
      is.na(`Othr Pmnt`),
      is.na(`Rate 2`)
    )
}

#' Group data by Tenor and Date, Return days with observations > obs_
#'
#' @param df 
#'
#' @return
#' @export
#'
#' @examples
process_data <- function(df, min_obs = 5) {
  df %>%
    group_by(tenor = `T`, Trade_Date = date(`Trade Time`)) %>%
    summarize(obs = n(), roll = roll_measure(`Rate 1`), Curr = last(Curr)) %>%
    filter(tenor %in% c("2Y", "5Y", "10Y"), obs > min_obs)
}
