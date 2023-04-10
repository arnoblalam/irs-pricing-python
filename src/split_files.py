#!/usr/bin/env python3

import pandas as pd
import os
import argparse

def parse_arguments():
    parser = argparse.ArgumentParser(description='Split Excel file based on date in the Trade Time column')
    parser.add_argument('input_file', help='Input Excel file')
    parser.add_argument('output_dir', help='Output directory for the split Excel files')
    parser.add_argument('-c', '--create', help='Create output directory if it does not exist', action='store_true')
    return parser.parse_args()

def main():
    args = parse_arguments()

    # Read the Excel file
    df = pd.read_excel(args.input_file)

    # Filter rows based on the conditions: Type is 'IRS Fix-Float' and Clr is 'C'
    filtered_df = df[(df['Type'] == 'IRS Fix-Float') & (df['Clr'] == 'C')]

    # Extract date from the 'Trade Time' column and store it in a new column called 'Trade Date'
    filtered_df['Trade Date'] = pd.to_datetime(filtered_df['Trade Time']).dt.date

    # Group the DataFrame by 'Trade Date'
    grouped_df = filtered_df.groupby('Trade Date')

    # Check if the output directory exists
    if not os.path.exists(args.output_dir):
        if args.create:
            os.makedirs(args.output_dir)
        else:
            print(f"Error: Output directory '{args.output_dir}' does not exist. Use '-c' option to create it.")
            return

    # Write each group to a separate Excel file
    for date, group in grouped_df:
        output_file = os.path.join(args.output_dir, f'{date}_output.xlsx')
        group.to_excel(output_file, index=False)

if __name__ == "__main__":
    main()
