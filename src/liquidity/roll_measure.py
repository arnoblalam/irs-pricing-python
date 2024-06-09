#!/usr/bin/env python3

# Name: roll_measure.py
# Last Uopdated: 2024-06-09
# Maintainer: Arnob L. Alam (arnoblalam@gmail.com)

# Description: This script processes trade data to estimate bid and ask prices 
# using the Roll (1984) estimator.



import pandas as pd
import numpy as np
import argparse

def calculate_roll_measure(prices):
    """
    Calculate the Roll measure from a list of trade prices.
    
    Parameters:
    prices (list or numpy array): A list or numpy array of trade prices.
    
    Returns:
    float: The Roll measure in decimal form.
    """    
    # Calculate the price changes (Delta P_t)
    delta_P_t = np.diff(np.log(prices))
    
    # Calculate the covariance between delta_P_t and delta_P_t_minus_1
    delta_P_t_minus_1 = delta_P_t[:-1]
    delta_P_t = delta_P_t[1:]
    
    cov = np.cov(delta_P_t, delta_P_t_minus_1, ddof=0)[0, 1]
    
    # Calculate the roll measure
    roll_measure = 2 * np.sqrt(-cov)
    
    # Convert the roll measure to basis points
    roll_measure_bps = roll_measure * 100
    
    return roll_measure, roll_measure_bps

def apply_roll_measure(group):
    # Extract the prices as a numpy array
    prices = group['Rate 1'].values
    # Calculate the roll measure
    roll_measure, roll_measure_bps = calculate_roll_measure(prices)
    return pd.Series({'Roll Measure': roll_measure, 'Roll Measure (bps)': roll_measure_bps})

def main(input_file, output_file, tenor):
    # Read data and create columns for tenor
    df = pd.read_excel(input_file)
    df['Tenor'] = np.round((df['Maturity'] - df['Effective']).dt.days / 365.25)
    df['Trade Date'] = df['Trade Time'].dt.date

    # Filter data
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
    filtered_df = filtered_df.sort_values('Trade Time')

    # Apply the roll measure
    result = filtered_df.groupby('Trade Date').apply(apply_roll_measure).reset_index()

    # Save the result to an Excel file
    result.to_excel(output_file)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Calculate the Roll measure for a given dataset.')
    parser.add_argument('input_file', type=str, help='Path to the input Excel file')
    parser.add_argument('output_file', type=str, help='Path to the output Excel file')
    parser.add_argument('tenor', type=float, help='Tenor value for filtering the dataset')

    args = parser.parse_args()

    main(args.input_file, args.output_file, args.tenor)
