#!/usr/bin/env python3

import pandas as pd
import argparse

# Function to calculate Roll's spread estimator for groups
def rolls_estimator(group):
    rates = group['Rate 1'].diff().dropna()
    cov_rate = rates.cov(rates.shift())
    return 2 * (abs(cov_rate) ** 0.5) if cov_rate < 0 else 0

def compute_roll_measure_by_group(file_name):
    # Load the dataset
    df = pd.read_excel(file_name)

    df = df.sort_values(by=['Trade Time'])
    
    # Apply filters
    filtered_df = df[
        (df['Type'] == 'IRS Fix-Float') &
        (df['CD'] == 'TR') &
        ((df['Leg 1'] == 'FIXED') | (df['Leg 1'] == 'CAD-BA-CDOR')) &
        (df['Leg 2'].isin(['FIXED', 'CAD-BA-CDOR', ''])) &
        (df['PF 1'] != '1T') &
        (df['PF 2'] != '1T') &
        (df['Curr'] == 'CAD') &
        (df['Othr Pmnt'].isnull()) &
        (df['Rate 2'].isnull())
    ]
    
    # Add Trade Date column
    filtered_df['Trade Date'] = pd.to_datetime(filtered_df['Trade Time']).dt.date
    
    # Calculate tenor in years and round
    filtered_df['Tenor_Years'] = (pd.to_datetime(filtered_df['Maturity']) - pd.to_datetime(filtered_df['Effective'])).dt.days / 365.25
    filtered_df['Tenor_Years_Rounded'] = filtered_df['Tenor_Years'].round()
    
    # Group by 'Tenor_Years_Rounded' and 'Trade Date'
    grouped = filtered_df.groupby(['Tenor_Years_Rounded', 'Trade Date'])
    
    # Apply the function to each group and reset index for better readability
    return(grouped.apply(rolls_estimator).reset_index(name='Roll_Measure'))

def main():
    # Create parser
    parser = argparse.ArgumentParser(
        description='Compute Roll\'s estimator for each trading day and tenor, and save to Excel.')
    parser.add_argument('file_name', type=str, help='Excel file containing swap data.')
    parser.add_argument('--output', type=str, help='Output file name.', default='Roll_Measure_Output.xlsx')
    
    # Parse arguments
    args = parser.parse_args()

    # Execute the computation
    result = compute_roll_measure_by_group(args.file_name)
    result.to_excel(args.output, index=False)

if __name__ == "__main__":
    main()