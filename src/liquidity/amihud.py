#!/usr/bin/env python3


import pandas as pd
import numpy as np
import argparse

def calculate_average_daily_return(prices):
    """
    Calculate the average daily return from a list of trade prices.
    
    Parameters:
    prices (list or numpy array): A list or numpy array of trade prices.
    
    Returns:
    float: The average daily return.
    """
    # Calculate the log of rate 1
    log_prices = np.log(prices)
    
    # Calculate the first difference
    delta_log_prices = np.diff(log_prices)
    
    # Calculate the average of the first difference
    average_daily_return = np.mean(delta_log_prices)
    
    return average_daily_return


def calculate_total_daily_volume(volumes):
    """
    Calculate the total daily volume.
    
    Parameters:
    volumes (list or numpy array): A list or numpy array of volumes.
    
    Returns:
    float: The total daily volume.
    """
    return np.sum(volumes)

def apply_measures(group):
    # Extract the prices and volumes as numpy arrays
    prices = group['Rate 1'].values
    volumes = group['Not.'].values
    
    # Calculate the average daily return
    avg_daily_return = calculate_average_daily_return(prices)
    
    # Calculate the total daily volume
    total_volume = calculate_total_daily_volume(volumes)
    
    # Calculate the ratio of average daily return to total daily volume
    ratio = 1e12 * avg_daily_return / total_volume if total_volume != 0 else np.nan
    
    # Calculate the number of observations in each group
    num_observations = group.shape[0]

    return pd.Series({
        'Average Daily Return': avg_daily_return,
        'Total Daily Volume': total_volume,
        'Ratio': ratio,
        'Num Observations': num_observations
    })

def main(input_file, output_file, tenor, currency):
    # Read data and create columns for tenor
    df = pd.read_excel(input_file)
    df['Tenor'] = np.round((df['Maturity'] - df['Effective']).dt.days / 365.25)
    df['Trade Date'] = df['Trade Time'].dt.date

    # Filter data
    if currency == 'CAD':
        index = 'CAD-BA-CDOR'
        Curr = 'CAD'
    else:
        index = 'USD-LIBOR-BBA'
        Curr = 'USD'
    filtered_df = df[
        (df['Type'] == 'IRS Fix-Float') &
        (df['CD'] == 'TR') &
        ((df['Leg 1'] == 'FIXED') | (df['Leg 1'] == index)) &
        (df['Leg 2'].isin(['FIXED', index, ''])) &
        (df['PF 1'] != '1T') &
        (df['PF 2'] != '1T') &
        (df['Curr'] == Curr) &
        (df['Tenor'] == tenor) &
        (df['Othr Pmnt'].isnull()) &
        (df['Rate 2'].isnull()) &
        (df['Rate 1'] > -10)&
        (df['Rate 1'] < 10)
    ]
    filtered_df = filtered_df.sort_values('Trade Time')

    # Apply the roll measure
    result = filtered_df.groupby('Trade Date').apply(apply_measures).reset_index()

    # Save the result to an Excel file
    result.to_excel(output_file)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Calculate the Roll measure for a given dataset.')
    parser.add_argument('input_file', type=str, help='Path to the input Excel file')
    parser.add_argument('output_file', type=str, help='Path to the output Excel file')
    parser.add_argument('tenor', type=float, help='Tenor value for filtering the dataset')
    parser.add_argument('currency', default='CAD', 
                        help='Currency value for filtering the dataset')


    args = parser.parse_args()

    main(args.input_file, args.output_file, args.tenor, args.currency)
