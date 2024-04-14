import pandas as pd
import argparse

def recode_rates(rate):
    """ Recode rates to account for basis points. """
    if rate > 15:  # Assuming rates above 15 are in bps
        return rate / 100
    return rate

def calculate_bid_ask_spread(file_path):
    # Load the Excel file
    df = pd.read_excel(file_path)
    
    # Convert 'Trade Time' and 'Effective' to datetime
    df['Trade Time'] = pd.to_datetime(df['Trade Time'])
    df['Effective'] = pd.to_datetime(df['Effective'])

    df['Rates recoded'] = df['Rate 1'].apply(recode_rates)
    
    # Calculate the difference between 'Trade Time' and 'Effective' in days
    df['Time Difference'] = (df['Effective'] - df['Trade Time'] ).dt.days
    
    # Apply filters
    filtered_df = df[
        (df['Othr Pmnt'].isna()) & 
        (df['T'] == '10Y') &
        (df['Leg 2'] == 'CAD-BA-CDOR') & 
        (df['Rate 2'].isna()) &
        (df['Time Difference'] <= 7)
        
    ]
    
    # Filter out observations outside the 1st and 99th percentiles
    lower_bound = filtered_df['Rates recoded'].quantile(0.05)
    upper_bound = filtered_df['Rates recoded'].quantile(0.95)
    
    # Calculate the bid-ask spread
    bid_ask_spread = upper_bound - lower_bound
    bid_ask_spread_basis_points = bid_ask_spread * 100
    
    return bid_ask_spread_basis_points

def main():
    parser = argparse.ArgumentParser(description='Calculate the bid-ask spread for 10Y contracts from an Excel file.')
    parser.add_argument('file_path', type=str, help='The path to the Excel file containing the contracts data.')
    
    args = parser.parse_args()
    spread = calculate_bid_ask_spread(args.file_path)

    # Extracting the file name from the file path for printing
    file_name = args.file_path.split('/')[-1]  # This extracts the file name from the path
    
    print(f"{file_name},{spread:.2f}")

if __name__ == "__main__":
    main()
