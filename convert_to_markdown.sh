#!/bin/bash

# Read JSON data from the input file
input_file="gasReporterOutput.json"
json_data=$(cat "$input_file")

# Extract methods information
methods_info=$(echo "$json_data" | jq -r '.info.methods | to_entries[]')

# Create Markdown table header
markdown_table="| Contract | Method | Gas Data | # calls |\n"
markdown_table+="|----------|--------|----------|---------|\n"

# Loop through methods and add rows to the Markdown table
while IFS= read -r method_entry; do
    contract=$(echo "$method_entry" | jq -r '.value.contract')
    method=$(echo "$method_entry" | jq -r '.value.method')
    gas_data=$(echo "$method_entry" | jq -r '.value.gasData | join(", ")')
    num_calls=$(echo "$method_entry" | jq -r '.value.numberOfCalls')
    markdown_table+="| $contract | $method | $gas_data | $num_calls |\n"
done <<< "$methods_info"

# Save the Markdown table to an output file
output_file="gas_report.md"
echo -e "$markdown_table" > "$output_file"

echo "Markdown table saved to $output_file"
