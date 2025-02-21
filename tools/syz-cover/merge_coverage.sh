#!/bin/bash
COVERAGE_DIR="/home/navneet/syzkaller/bin/linux_arm64/run1/linux_arm64/"
CONFIG_FILE="/home/navneet/syzkaller/config.json"
BATCH_SIZE=7000  # Number of files per batch
OUTPUT_DIR="intermediate_reports_clang"

# Merge intermediate reports into the final report
echo "Merging all batches into the final report..."
INTERMEDIATE_FILES=$(find "$OUTPUT_DIR" -type f -name "*.raw")
go run syz-cover.go -config "$CONFIG_FILE" -exports cover -force -debug $INTERMEDIATE_FILES 
echo "Final coverage report generated: syz-cover.html"