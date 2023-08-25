#!/bin/bash

input_file="$1"
output_file="$2"

echo "| Contract | Method | Min | Max | Avg | # calls | USD (avg) |" > "$output_file"
echo "|----------|--------|-----|-----|-----|---------|-----------|" >> "$output_file"

awk -F'|' '/^[[:space:]]*\|/{print $2, $3, $4, $5, $6, $7, $8}' "$input_file" >> "$output_file"
