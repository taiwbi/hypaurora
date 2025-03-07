#!/bin/bash

# Set the file path
FILE=$HOME/.bashrc.d/2B-praise

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo "Error: File not found at $FILE"
    exit 1
fi

# Count total lines in the file
total_lines=$(wc -l < "$FILE")

# Check if file is empty
if [ "$total_lines" -eq 0 ]; then
    echo "Error: File is empty"
    exit 1
fi

# Generate random line number
random_line=$(( RANDOM % total_lines + 1 ))

# Get the random line
line=$(sed -n "${random_line}p" "$FILE")

# Get length of the line
line_length=${#line}

# If line is 80 characters or less, print it and exit
if [ "$line_length" -le 80 ]; then
    echo "$line"
    exit 0
fi

# Find the last space before 80 characters
# Cut the string to 80 chars and find last space
first_part="${line:0:80}"
last_space=$(echo "$first_part" | grep -o ' [^ ]*$' | tail -1)
last_space_pos=$((80 - ${#last_space} + 1))

# If no space found, just cut at 80
if [ "$last_space" = "" ]; then
    echo "${line:0:80}"
    echo "${line:80}"
else
    # Print first part up to last space
    echo "${line:0:$last_space_pos}"
    # Print remainder
    echo "${line:$last_space_pos}"
fi
