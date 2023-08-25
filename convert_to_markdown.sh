#!/bin/bash

# Read JSON data from the input file
input_file="gasReporterOutput.json"
json_data=$(cat "$input_file")

# Extract methods information
methods_info=$(echo "$json_data" | jq -r '.info.methods')

# Create Markdown table header
markdown_table="| Contract | Method | Gas Data | # calls |\n"
markdown_table+="|----------|--------|----------|---------|\n"

# Loop through methods and add rows to the Markdown table
while IFS= read -r method_info; do
    contract=$(echo "$method_info" | jq -r '.contract')
    method=$(echo "$method_info" | jq -r '.method')
    gas_data=$(echo "$method_info" | jq -r '.gasData | join(", ")')
    num_calls=$(echo "$method_info" | jq -r '.numberOfCalls')
    markdown_table+="| $contract | $method | $gas_data | $num_calls |\n"
done <<< "$methods_info"

# Save the Markdown table to an output file
output_file="gas_report.md"
echo -e "$markdown_table" > "$output_file"

echo "Markdown table saved to $output_file"
