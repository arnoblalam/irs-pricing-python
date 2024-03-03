#!/bin/zsh

for file in usd_*.xlsx; do
    # Extract the base name without extension
    base=$(basename "$file" .xlsx)
    
    # Extract the date part from the filename
    date_part=${base#usd_}
    
    # Check if the date part is in the yyyymmdd format
    if [[ $date_part =~ ^2013[0-9]{4}$ ]]; then
        # Convert from yyyymmdd to mmddyyyy
        new_date_part="${date_part:4:2}${date_part:6:2}${date_part:0:4}"
    else
        # If the file doesn't match the yyyymmdd pattern, skip it
        continue
    fi

    # Construct the new filename
    new_file="usd_${new_date_part}.xlsx"

    # Rename the file
    mv "$file" "$new_file"
done
