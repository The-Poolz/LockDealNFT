#!/bin/bash

input_file="$1"
output_file="$2"

awk -F'|' '
    /^[[:space:]]*\|/{sub(/^\| /, ""); sub(/ \|\s*$/, ""); print}
' "$input_file" > "$output_file"
