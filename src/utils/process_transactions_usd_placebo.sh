#!/bin/zsh

# Set the base directories for transactions, yield curves, and output files
transaction_base="data/processed/USD/placebo"
yield_curve_base="data/raw/curves/USD"
output_base="data/results/USD/placebo"

# Create the output directory if it doesn't exist
mkdir -p "$output_base"

# Function to convert date format from YYYY-MM-DD to MMDDYYYY
function convert_date_format() {
    echo "$(echo $1 | cut -c6-7)$(echo $1 | cut -c9-10)$(echo $1 | cut -c1-4)"
}

# Loop through all transaction files in the transaction_base directory
for transaction_file in "$transaction_base"/*_output.xlsx; do
    # Extract the date from the transaction file name
    date_str=$(basename "$transaction_file" "_output.xlsx")

    # Convert date_str to the format used in the curve data files
    curve_date_str=$(convert_date_format "$date_str")

    # Set the corresponding yield curve file path
    yield_curve_file="$yield_curve_base/usd_${curve_date_str}.xlsx"

    # Set the output file path
    output_file="$output_base/USD_${date_str}_priced.xlsx"

    # Set the evaluation date
    evaluation_date="$date_str"

    # Run the price_swaps.py script with the required arguments
    ./src/price_swaps_usd.py "$transaction_file" "$yield_curve_file" "$output_file" "$evaluation_date"
done
