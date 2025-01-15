#!/usr/bin/env python3

import pandas as pd
import argparse

def rolls_estimator(prices):
    '''Take a vector of prices and calculate the Roll Measure'''
    d_prices = prices.diff().dropna()
    cov_ = d_prices.cov(d_prices.shift())
    return 2 * (-cov_) ** 0.5 if cov_ < 0 else 0

def apply_filters_and_sort(df):
    '''Take a data frame of IRS contracts and filter out funky values and sorted by Trade Time'''
    return df[
        (df['Type'] == 'IRS Fix-Float') &
        (df['CD'] == 'TR') &
        ((df['Leg 1'] == 'FIXED') | (df['Leg 1'] == 'USD-LIBOR-BBA')) &
        (df['Leg 2'].isin(['FIXED', 'USD-LIBOR-BBA', ''])) &
        (df['PF 1'] != '1T') &
        (df['PF 2'] != '1T') &
        #((pd.to_datetime(df['Effective']) - pd.to_datetime(df['Trade Time'])).dt.days <= 7) &
        (df['Curr'] == 'USD') &
        (df['Othr Pmnt'].isnull()) &
        (df['Rate 2'].isnull())
    ].sort_values(by = 'Trade Time')

def compute_bid_ask_spread(file_name):
    # Load the dataset
    df = pd.read_excel(file_name)
    
    # Apply filters and sort data
    filtered_df = apply_filters_and_sort(df)
    
    # Calculate tenor in years and round
    #filtered_df['Tenor_Years'] = (pd.to_datetime(filtered_df['Maturity']) - pd.to_datetime(filtered_df['Effective'])).dt.days / 365.25
    #filtered_df['Tenor_Years_Rounded'] = filtered_df['Tenor_Years'].round()

    # Group the data by date and tenor
    filtered_df.groupby('T').groupby('Trade Time'.dt.date)
    
    # Calculate spreads
    spread_10_year = rolls_estimator("10Y")
    spread_5_year = rolls_estimator("5Y")
    spread_2_year = rolls_estimator("2Y")
    
    # Print results
    print(f"{file_name},{spread_10_year:.4f},{spread_5_year:.4f}")

def main():
    # Create parser
    parser = argparse.ArgumentParser(description='Compute Roll\'s estimator for bid-ask spread for Interest Rate Swaps contracts.')
    parser.add_argument('file_name', type=str, help='Excel file containing swap data.')
    
    # Parse arguments
    args = parser.parse_args()

    # Execute the computation
    compute_bid_ask_spread(args.file_name)

if __name__ == "__main__":
    main()
