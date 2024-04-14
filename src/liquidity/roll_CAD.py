#!/usr/bin/env python3

import pandas as pd
import argparse

def compute_bid_ask_spread(file_name):
    # Load the dataset
    df = pd.read_excel(file_name)
    
    # Apply filters
    filtered_df = df[
        (df['Type'] == 'IRS Fix-Float') &
        (df['CD'] == 'TR') &
        ((df['Leg 1'] == 'FIXED') | (df['Leg 1'] == 'CAD-BA-CDOR')) &
        (df['Leg 2'].isin(['FIXED', 'CAD-BA-CDOR', ''])) &
        (df['PF 1'] != '1T') &
        (df['PF 2'] != '1T') &
        ((pd.to_datetime(df['Effective']) - pd.to_datetime(df['Trade Time'])).dt.days <= 7) &
        (df['Curr'] == 'CAD') &
        (df['Othr Pmnt'].isnull()) &
        (df['Rate 2'].isnull())
    ]
    
    # Ensure contracts are ordered by Trade Time
    filtered_df = filtered_df.sort_values(by='Trade Time')
    
    # Calculate tenor in years and round
    filtered_df['Tenor_Years'] = (pd.to_datetime(filtered_df['Maturity']) - pd.to_datetime(filtered_df['Effective'])).dt.days / 365.25
    filtered_df['Tenor_Years_Rounded'] = filtered_df['Tenor_Years'].round()
    
    # Function to calculate Roll's spread estimator
    def rolls_estimator(contract_length):
        df_contract = filtered_df[filtered_df['Tenor_Years_Rounded'] == contract_length]['Rate 1'].diff().dropna()
        cov_contract = df_contract.cov(df_contract.shift())
        return 2 * (abs(cov_contract) ** 0.5) if cov_contract < 0 else 0
    
    # Calculate spreads
    spread_10_year = rolls_estimator(10)
    spread_5_year = rolls_estimator(5)
    
    # Print results
    print(f"{file_name},{spread_10_year:.4f},{spread_5_year:.4f}")

def main():
    # Create parser
    parser = argparse.ArgumentParser(description='Compute Roll\'s estimator for bid-ask spread of interest rate swaps.')
    parser.add_argument('file_name', type=str, help='Excel file containing swap data.')
    
    # Parse arguments
    args = parser.parse_args()

    # Execute the computation
    compute_bid_ask_spread(args.file_name)

if __name__ == "__main__":
    main()
