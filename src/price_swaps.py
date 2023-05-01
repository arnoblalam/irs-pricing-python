#!/usr/bin/env python3

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
    for _, row in yield_curve_df.iterrows():
        tenor, description, rate, source, update = row['Tenor'], row['Description'], row['Yield'], row['Source'], parse_date(row['Update'])

        if 'Index' in description:
            rate_helpers.append(ql.DepositRateHelper(ql.QuoteHandle(ql.SimpleQuote(rate/100)), 
                                                     ql.Period(tenor), 
                                                     2, 
                                                     ql.UnitedStates(), 
                                                     ql.ModifiedFollowing, 
                                                     False, 
                                                     ql.Actual360()))
        elif 'Comdty' in description:
            price = 100 - rate  # Convert quote to price
            imm_date = ql.IMM.nextDate(update)
            rate_helpers.append(ql.FuturesRateHelper(price, imm_date, ql.USDLibor(ql.Period(tenor))))
        elif 'BGN Curncy' in description:
            rate_helpers.append(ql.SwapRateHelper(ql.QuoteHandle(ql.SimpleQuote(rate/100)), 
                                                  ql.Period(tenor), ql.UnitedStates(), 
                                                  ql.Annual, 
                                                  ql.Unadjusted, 
                                                  ql.Thirty360(ql.Thirty360.BondBasis), 
                                                  ql.USDLibor(ql.Period('3M'))))
    
    return rate_helpers

def build_yield_curve(rate_helpers, evaluation_date):
    yield_curve = ql.PiecewiseFlatForward(evaluation_date, rate_helpers, ql.Actual365Fixed())
    yield_curve.enableExtrapolation()
    return yield_curve

def price_swaps(transaction_df, yield_curve, index):
    results = []
    for _, row in transaction_df.iterrows():
        try:
            effective_date, maturity_date, rate_1, leg_1, rate_2, leg_2, currency, notional, payment_frequency_1, payment_frequency_2 = parse_date(row['Effective']), parse_date(row['Maturity']), row['Rate 1'], row['Leg 1'], row['Rate 2'], row['Leg 2'], row['Curr'], row['Not.'], row['PF 1'], row['PF 2']
            fixed_leg_frequency = ql.Period(payment_frequency_1 if leg_1 == 'FIXED' else payment_frequency_2)
            float_leg_frequency = ql.Period(payment_frequency_1 if leg_1 != 'FIXED' else payment_frequency_2)

            fixed_rate = rate_1 if leg_1 == 'FIXED' else rate_2
            fixed_rate /= 100 if fixed_rate > 10 else 1

            float_rate = rate_1 if leg_1 != 'FIXED' else rate_2
            float_rate /= 100 if float_rate > 10 else 1

            if pd.isnull(float_rate):
                float_rate = 0

            index = index.clone(ql.YieldTermStructureHandle(yield_curve))

            swap_engine = ql.DiscountingSwapEngine(ql.YieldTermStructureHandle(yield_curve))

            fixed_schedule = ql.Schedule(effective_date, 
                                        maturity_date, 
                                        fixed_leg_frequency, 
                                        ql.UnitedStates(), 
                                        ql.ModifiedFollowing, 
                                        ql.ModifiedFollowing, 
                                        ql.DateGeneration.Forward, 
                                        False)
            float_schedule = ql.Schedule(effective_date, maturity_date, 
                                        float_leg_frequency, 
                                        ql.UnitedStates(), 
                                        ql.ModifiedFollowing, 
                                        ql.ModifiedFollowing, 
                                        ql.DateGeneration.Forward, 
                                        False)
            swap = ql.VanillaSwap(ql.VanillaSwap.Payer, 
                                notional, 
                                fixed_schedule, 
                                fixed_rate/100, 
                                ql.Thirty360(ql.Thirty360.BondBasis), 
                                float_schedule, 
                                index, 
                                float_rate/100, 
                                index.dayCounter())
            swap.setPricingEngine(swap_engine)
            fair_rate = swap.fairRate()*100
            difference = (fixed_rate - fair_rate)*100

            row['Fair Rate'] = fair_rate
            row['Difference'] = difference
            results.append(row)

        except Exception as e:
            logging.exception(f"Error processing swap:\n{row}\nError: {str(e)}")
            continue
    
    return pd.DataFrame(results)

def main():
    args = parse_arguments()

    yield_curve_data = pd.read_excel(args.yield_curve_file)
    transactions_data = pd.read_excel(args.transaction_file)

    evaluation_date_dt = datetime.strptime(args.evaluation_date, '%Y-%m-%d')
    evaluation_date = ql.Date(evaluation_date_dt.day, evaluation_date_dt.month, evaluation_date_dt.year)
    ql.Settings.instance().evaluationDate = evaluation_date

    rate_helpers = build_helpers(yield_curve_data)
    yield_curve = build_yield_curve(rate_helpers, evaluation_date)

    # Create the USD Libor 3M index
    index = ql.USDLibor(ql.Period('3M'), ql.YieldTermStructureHandle(yield_curve))

    historical_fixings = [       
        ("2013-02-15", 0.2901/100),
        ("2013-02-19", 0.2891/100),
        ("2013-02-20", 0.2891/100),
        ("2013-02-21", 0.2881/100),
        ("2013-02-22", 0.2881/100),
        ("2013-02-25", 0.2866/100),
        ("2013-02-27", 0.2871/100)]

    for date, fixing in historical_fixings:
        fixing_date = datetime.strptime(date, "%Y-%m-%d")
        ql_fixing_date = ql.Date(fixing_date.day, fixing_date.month, fixing_date.year)
        index.addFixing(ql_fixing_date, fixing)


    priced_swaps_df = price_swaps(transactions_data, yield_curve, index)
    priced_swaps_df.to_excel(args.output_file, index=False)

    if args.log_file:
        with open(args.log_file, 'a') as log_file:
            log_file.write(f"Successfully processed swaps and saved output to {args.output_file}\n")

if __name__ == "__main__":
    main()