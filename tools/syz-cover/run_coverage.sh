#!/bin/bash

# Directory containing raw coverage files
COVERAGE_DIR="/home/navneet/syzkaller/bin/linux_arm64/run_clang_retsan/"
CONFIG_FILE="/home/navneet/syzkaller/config.json"
BATCH_SIZE=7000  # Number of files per batch
OUTPUT_DIR="intermediate_reports_clang"

# Create output directory for intermediate reports
mkdir -p "$OUTPUT_DIR"

# Initialize batch counter
batch=0
count=0

trap 'echo ${count}' SIGINT
# Process files in batches
# find "$COVERAGE_DIR" -type f -name "coverfile_prog*" | while read -r file; do
#     files_in_batch+=("$file")
#     ((count+=1))
#     if (( ${#files_in_batch[@]} == BATCH_SIZE )); then
#         batch=$((batch + 1))
#         echo "Processing batch $batch..."
#         # echo "${files_in_batch[@]}"
#         go run syz-cover.go -config "$CONFIG_FILE" -force -debug -exports rawcover "${files_in_batch[@]}" 
#         mv rawcoverpcs "$OUTPUT_DIR/batch_$batch.raw"
#         files_in_batch=()
#     fi
# done

while read -r file; do
    files_in_batch+=("$file")
    ((count+=1))
    if (( ${#files_in_batch[@]} == BATCH_SIZE )); then
        batch=$((batch + 1))
        echo "Processing batch $batch..."
        go run syz-cover.go -config "$CONFIG_FILE" -force -debug -exports rawcover "${files_in_batch[@]}" 
        mv rawcoverpcs "$OUTPUT_DIR/batch_$batch.raw"
        files_in_batch=()
    fi
done < <(find "$COVERAGE_DIR" -type f -name "coverfile_prog*")

# Process remaining files (if any)
if (( ${#files_in_batch[@]} > 0 )); then

    batch=$((batch + 1))
    echo "Processing final batch $batch..."
    # echo "${files_in_batch[@]}"
    go run syz-cover.go -config "$CONFIG_FILE" -force -exports rawcover "${files_in_batch[@]}"
    mv rawcoverpcs "$OUTPUT_DIR/batch_$batch.raw" 
fi


echo "Count is: ${count}"
# Merge intermediate reports into the final report
# echo "Merging all batches into the final report..."
# INTERMEDIATE_FILES=$(find "$OUTPUT_DIR" -type f -name "*.raw")
# syz-cover -config "$CONFIG_FILE" $INTERMEDIATE_FILES -exports cover
# echo "Final coverage report generated: syz-cover.html"
