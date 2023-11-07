import argparse
import pandas as pd

def recode_rates(rate):
    """ Recode rates to account for basis points. """
    if rate > 15:  # Assuming rates above 15 are in bps
        return rate / 100
    return rate

def lee_ready_algorithm(data, rate_col, time_col):
    """ Apply the Lee and Ready (1991) trade classification algorithm. """
    data_sorted = data.sort_values(by=[time_col, rate_col]).reset_index(drop=True)
    data_sorted['Proxy Mid-Quote'] = data_sorted[rate_col].shift(1)
    data_sorted['Trade Direction'] = 0
    data_sorted.loc[data_sorted[rate_col] > data_sorted['Proxy Mid-Quote'], 'Trade Direction'] = 1
    data_sorted.loc[data_sorted[rate_col] < data_sorted['Proxy Mid-Quote'], 'Trade Direction'] = -1
    data_sorted['Trade Direction'] = data_sorted['Trade Direction'].replace(to_replace=0, method='ffill')
    data_sorted['Estimated Ask'] = data_sorted.apply(lambda x: x[rate_col] if x['Trade Direction'] == 1 else None, axis=1)
    data_sorted['Estimated Bid'] = data_sorted.apply(lambda x: x[rate_col] if x['Trade Direction'] == -1 else None, axis=1)
    data_sorted['Estimated Ask'] = data_sorted['Estimated Ask'].ffill()
    data_sorted['Estimated Bid'] = data_sorted['Estimated Bid'].ffill()
    data_sorted['Estimated Spread'] = data_sorted['Estimated Ask'] - data_sorted['Estimated Bid']
    return data_sorted

def process_file(input_file, output_file):
    """ Process the Excel file to recode rates and apply Lee and Ready algorithm. """
    # Read the Excel file
    data = pd.read_excel(input_file)

    # Recode rates
    data['Rates recoded'] = data['Rate 1'].apply(recode_rates)

    # Run the Lee and Ready algorithm
    results = lee_ready_algorithm(data, 'Rates recoded', 'Trade Time')

    # Save results to the specified output file
    results.to_excel(output_file, index=False)
    print(f'Processed file saved as "{output_file}".')

def main():
    parser = argparse.ArgumentParser(description="Process trade data for bid and ask price estimation.")
    parser.add_argument('input_file', type=str, help="The Excel file containing trade data.")
    parser.add_argument('output_file', type=str, help="The Excel file to save processed data.")
    args = parser.parse_args()

    process_file(args.input_file, args.output_file)

if __name__ == "__main__":
    main()
