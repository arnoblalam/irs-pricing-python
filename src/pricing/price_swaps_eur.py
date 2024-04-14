#!/usr/bin/env python3

# Name: price_swaps_cad.py
# Last Updated: 2023-05-06
# Maintainer: Arnob L. Alam (arnoblalam@gmail.com)
#
# Description: This script prices interest rate swaps using QuantLib for the CAD currency.

import argparse
import pandas as pd
import numpy as np
import QuantLib as ql
from datetime import datetime
import logging


def parse_arguments():
    parser = argparse.ArgumentParser(description='Price interest rate swaps using QuantLib')
    parser.add_argument('transaction_file', help='Transaction data Excel file')
    parser.add_argument('yield_curve_file', help='Yield curve data Excel file')
    parser.add_argument('output_file', help='Output Excel file')
    parser.add_argument('evaluation_date', help='Evaluation date (in format YYYY-MM-DD)')
    parser.add_argument('--log_file', help='Optional log file', default=None)

    return parser.parse_args()

def read_data(transaction_file, yield_curve_file):
    transactions_df = pd.read_excel(transaction_file)
    yield_curve_df = pd.read_excel(yield_curve_file)
    return transactions_df, yield_curve_df

def parse_date(date_string):
    formats = ["%m/%d/%Y", "%m/%d/%y"]

    for date_format in formats:
        try:
            return ql.DateParser.parseFormatted(date_string, date_format)
        except:
            pass


def build_helpers(yield_curve_df):
    rate_helpers = []
    calendar = ql.TARGET()
    settlement_days = 2
    fixing_days = 2  # Common for Euribor
    euribor6M = ql.Euribor6M()
    
    for _, row in yield_curve_df.iterrows():
        tenor, description, rate = row['Tenor'], row['Description'], row['Yield']
        
        # Adjusting for Euribor Index Rates using DepositRateHelper
        if 'Index' in description:
            rate_helpers.append(ql.DepositRateHelper(ql.QuoteHandle(ql.SimpleQuote(rate / 100)),
                                                     ql.Period(tenor),
                                                     fixing_days,
                                                     calendar,
                                                     ql.ModifiedFollowing,
                                                     False,
                                                     ql.Actual360()))
        
        # Adjusting for FRAs using FraRateHelper
        elif 'EUFR' in description:
            months = int(tenor[:-1]) if 'M' in tenor else int(tenor[:-1]) * 12
            rate_helpers.append(ql.FraRateHelper(ql.QuoteHandle(ql.SimpleQuote(rate / 100)),
                                                 months - settlement_days,  # Assuming the start period for FRA
                                                 months,
                                                 fixing_days,
                                                 calendar,
                                                 ql.ModifiedFollowing,
                                                 False,
                                                 ql.Actual360()))
        
        # Adjusting for Swap Rates using SwapRateHelper
        elif 'EUSA' in row['CUSIP']:
            rate_helpers.append(ql.SwapRateHelper(ql.QuoteHandle(ql.SimpleQuote(rate / 100)),
                                                  ql.Period(tenor),
                                                  calendar,
                                                  ql.Annual,
                                                  ql.Unadjusted,
                                                  ql.Thirty360(ql.Thirty360.European),
                                                  euribor6M))
    
    return rate_helpers


def build_yield_curve(rate_helpers, evaluation_date):
    yield_curve = ql.PiecewiseFlatForward(evaluation_date, rate_helpers, ql.Actual365Fixed())
    yield_curve.enableExtrapolation()
    return yield_curve

def price_swaps(transaction_df, yield_curve, index):
    results = []
    for _, row in transaction_df.iterrows():
        try:
            # Assuming parse_date is a function that converts a string to a QuantLib Date
            effective_date, maturity_date, rate_1, leg_1, rate_2, leg_2, currency, notional, payment_frequency_1, payment_frequency_2 = parse_date(row['Effective']), parse_date(row['Maturity']), row['Rate 1'], row['Leg 1'], row['Rate 2'], row['Leg 2'], row['Curr'], row['Not.'], row['PF 1'], row['PF 2']

            # Adjusting for Euro market conventions
            fixed_leg_frequency = ql.Period(payment_frequency_1 if leg_1 == 'FIXED' else payment_frequency_2)
            float_leg_frequency = ql.Period(payment_frequency_1 if leg_1 != 'FIXED' else payment_frequency_2)

            fixed_rate = rate_1 if leg_1 == 'FIXED' else rate_2
            fixed_rate /= 100 if fixed_rate > 1 else 1  # Adjusting rate conversion based on input format

            float_rate = rate_1 if leg_1 != 'FIXED' else rate_2
            float_rate /= 100 if float_rate > 1 else 1  # Adjusting rate conversion based on input format

            if pd.isnull(float_rate):
                float_rate = 0

            # Update for Euro market: Change index to use Euribor and the correct yield curve
            index = index.clone(ql.YieldTermStructureHandle(yield_curve))

            swap_engine = ql.DiscountingSwapEngine(ql.YieldTermStructureHandle(yield_curve))

            # Schedule adjustments for the Euro market
            fixed_schedule = ql.Schedule(effective_date, 
                                         maturity_date, 
                                         fixed_leg_frequency, 
                                         ql.TARGET(),  # Adjusting for the Euro market calendar
                                         ql.ModifiedFollowing, 
                                         ql.ModifiedFollowing, 
                                         ql.DateGeneration.Forward, 
                                         False)
            float_schedule = ql.Schedule(effective_date, 
                                         maturity_date, 
                                         float_leg_frequency, 
                                         ql.TARGET(),  # Adjusting for the Euro market calendar
                                         ql.ModifiedFollowing, 
                                         ql.ModifiedFollowing, 
                                         ql.DateGeneration.Forward, 
                                         False)

            # Adjusting day count conventions for the Euro market
            swap = ql.VanillaSwap(ql.VanillaSwap.Payer, 
                                  notional, 
                                  fixed_schedule, 
                                  fixed_rate,  # Assuming rate is already in decimal
                                  ql.Thirty360(ql.Thirty360.European), 
                                  float_schedule, 
                                  index, 
                                  float_rate,  # Assuming rate is already in decimal
                                  index.dayCounter())

            swap.setPricingEngine(swap_engine)
            fair_rate = swap.fairRate() * 100
            difference = (fixed_rate * 100 - fair_rate)  # Adjusting difference calculation

            # Constructing the result row
            result_row = row.copy()
            result_row['Fair Rate'] = fair_rate
            result_row['Difference'] = difference
            results.append(result_row)

        except Exception as e:
            logging.exception(f"Error processing swap:\n{row}\nError: {str(e)}")
            continue

    return pd.DataFrame(results)


import pandas as pd
import QuantLib as ql
from datetime import datetime

def main():
    args = parse_arguments()

    # Load data from Excel files
    yield_curve_data = pd.read_excel(args.yield_curve_file)
    transactions_data = pd.read_excel(args.transaction_file)
    
    # Adjust the path to the historical fixings file for Euribor or your specific needs
    # historical_fixings_data = pd.read_excel("data/raw/historical_fixings/EURIBOR_fixings.xlsx")

    # Set the evaluation date
    evaluation_date_dt = datetime.strptime(args.evaluation_date, '%Y-%m-%d')
    evaluation_date = ql.Date(evaluation_date_dt.day, evaluation_date_dt.month, evaluation_date_dt.year)
    ql.Settings.instance().evaluationDate = evaluation_date

    # Build the yield curve using Euro market data
    rate_helpers = build_helpers(yield_curve_data)  # Ensure this function is defined for Euro swaps
    yield_curve = build_yield_curve(rate_helpers, evaluation_date)  # Ensure this function is adapted for Euro market

    # Create the Euribor 3M index with the constructed yield curve
    index = ql.Euribor3M(ql.YieldTermStructureHandle(yield_curve))

    # Add historical fixings to the Euribor index
    # for _, row in historical_fixings_data.iterrows():
    #     fixing_date_dt = row['Date']
    #     fixing = row['PX_LAST'] / 100  # Convert percentage to decimal

    #     ql_fixing_date = ql.Date(fixing_date_dt.day, fixing_date_dt.month, fixing_date_dt.year)

    #     if ql_fixing_date <= evaluation_date:
    #         index.addFixing(ql_fixing_date, fixing)

    # Price the swaps using the Euro-based yield curve and index
    priced_swaps_df = price_swaps(transactions_data, yield_curve, index)  # Ensure this function is defined for Euro swaps
    priced_swaps_df.to_excel(args.output_file, index=False)

    # Log the success message, if a log file is specified
    if args.log_file:
        with open(args.log_file, 'a') as log_file:
            log_file.write(f"Successfully processed swaps and saved output to {args.output_file}\n")

# Ensure the helper functions (parse_arguments, build_helpers_euro, build_yield_curve, price_swaps_euro) are properly defined and adapted for Euro market
if __name__ == "__main__":
    main()
