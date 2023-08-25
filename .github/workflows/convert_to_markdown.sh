#!/bin/bash

# Read the input file
input_file=$1
output_file=$2

# Initialize the Markdown table header
echo "| Contract           | Method                                             | Min    | Max    | Avg    | # calls | USD (avg) |" > $output_file
echo "|--------------------|----------------------------------------------------|--------|--------|--------|---------|-----------|" >> $output_file

# Process each line in the input file
while IFS= read -r line
do
  # Use awk to extract the fields and format them into Markdown table rows
  echo "$line" | awk -F '·' '{printf("| %-20s | %-50s | %-6s | %-6s | %-6s | %-7s | %-9s |\n", $1, $2, $3, $4, $5, $6, $7)}' >> $output_file
done < "$input_file"
