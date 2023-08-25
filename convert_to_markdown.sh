#!/bin/bash

input_file="$1"
output_file="$2"

awk -F'[|·]' '
    /^[[:space:]]*\|/{gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print}
' "$input_file" > "$output_file"
