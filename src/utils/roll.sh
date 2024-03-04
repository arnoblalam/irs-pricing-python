#!/bin/zsh

# Define the directory containing the .xlsx files
DIRECTORY="data/processed/USD"

# Loop through all .xlsx files in the directory
for file in "$DIRECTORY"/*.xlsx; do
  # Execute the Python script with the current file as input
  /path/to/python3 /path/to/roll.py "$file"
done
