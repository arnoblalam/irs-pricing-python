#!/bin/zsh

# Path to the input and output directories
INPUT_DIR="data/results"
OUTPUT_DIR="data/bid_ask"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through all Excel files in the input directory
for file in "$INPUT_DIR"/*.xlsx; do
    # Extract the base filename without the extension
    base_name=${file:t:r}

    # Define the new filename by appending "_lee_ready" before the extension
    new_file="${base_name}_lee_ready.xlsx"

    # Call the Python script to process the file
    python ./src/lee_ready.py "$file" "$OUTPUT_DIR/$new_file"
done

echo "Processing complete. All files have been saved to $OUTPUT_DIR."
