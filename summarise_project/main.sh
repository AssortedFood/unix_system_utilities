#!/bin/bash

# Ensure at least one file extension is provided
if [ "$#" -eq 0 ]; then
    echo "❌ Usage: $0 <ext1> <ext2> ..."
    exit 1
fi

# Define output file
OUTPUT_FILE="output.txt"

# Clear previous output file if it exists
> "$OUTPUT_FILE"

echo "🚀 Starting script..."
echo "📝 Output will be saved to: $OUTPUT_FILE"

# List of folders and files to ignore
IGNORE_LIST=("node_modules" ".next" "package-lock.json" "venv")

# Add directory tree structure (excluding specified folders)
echo "📂 PROJECT DIRECTORY STRUCTURE" >> "$OUTPUT_FILE"
echo "──────────────────────────────" >> "$OUTPUT_FILE"
echo "📁 Adding directory tree structure to output file..."
tree -I "$(IFS='|'; echo "${IGNORE_LIST[*]}")" >> "$OUTPUT_FILE"
echo -e "\n\n" >> "$OUTPUT_FILE"

# Construct find command dynamically for file extensions
EXTS=()
for ext in "$@"; do
    EXTS+=("-name" "*.$ext" -o)
done
unset 'EXTS[-1]' # Remove the last "-o"

# Construct the ignore pattern for find
IGNORE_PATTERN=()
for ignore in "${IGNORE_LIST[@]}"; do
    IGNORE_PATTERN+=(! -path "*/$ignore/*") # Ignore directories
    IGNORE_PATTERN+=(! -name "$ignore")     # Ignore specific files
done

# Find matching files and store in an array, while excluding ignored directories and files
echo "🔍 Searching for files with extensions: $* (excluding ${IGNORE_LIST[*]})"
mapfile -t files < <(find . -type f \( "${EXTS[@]}" \) "${IGNORE_PATTERN[@]}")

# Counter for processed files
file_count=0

# Process each file
for file in "${files[@]}"; do
    ((file_count++))
    echo "📄 Processing: $file"
    echo "📄 FILE: $file" >> "$OUTPUT_FILE"
    echo "──────────────────────────────" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo -e "\n\n" >> "$OUTPUT_FILE"
done

# Summary
echo "✅ Processing complete!"
echo "📂 Total files written to output: $file_count"
echo "📄 Check the output in: $OUTPUT_FILE"
