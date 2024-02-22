#!/bin/zsh

# Define the directory containing the .xlsx files
DIRECTORY="data/processed/CAD"

# Path to the Python script
PYTHON_SCRIPT="src/simple_bid_ask.py"

# Loop through all .xlsx files in the specified directory
for FILE in "$DIRECTORY"/*.xlsx; do
  # Execute the Python script with the current file as an argument
  python $PYTHON_SCRIPT "$FILE"
done
