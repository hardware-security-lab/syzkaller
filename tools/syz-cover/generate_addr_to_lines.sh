#!/bin/bash

# Directory containing log files
LOG_DIR="/home/navneet/syzkaller/tools/syz-cover/intermediate_reports"
ERROR_LOG="errors.log"
RUN_LOG="run.log"
# Output Dircetory
OUTPUT_DIR="mapped"

# Path to vmlinux binary
VMLINUX_FILE="/home/navneet/oracular/debian/build/build-qcom-x1e/vmlinux"
MIN_ADDRESS=0xffff800080010000

# Clear or initialize logs
> "$ERROR_LOG"
> "$RUN_LOG"

# Ensure the log directory exists
if [[ ! -d "$LOG_DIR" ]]; then
    echo "Directory '$LOG_DIR' not found!"
    exit 1
fi

# Ensure the output directory exists (create if missing)
mkdir -p "$OUTPUT_DIR"

# Trap to kill background jobs on script exit or interrupt
trap 'kill $(jobs -p)' EXIT




parse_file() {
    local file="$1"
    local base_name=$(basename "$file" .raw)  # Strip directory and .raw extension
    local output_file="$OUTPUT_DIR/mapped_${base_name}.csv"  # Output in mapped directory
    echo "Address,Function,File" > "$output_file"

    echo "Processing file: $file" | tee -a "$RUN_LOG"
    
    while IFS= read -r line; do
        # Extract hexadecimal address
        address=$(echo "$line" | grep -oE '0x[0-9a-fA-F]+')

        # Check if address is valid and greater than the minimum address
        if [[ -n "$address" && "$address" > "$MIN_ADDRESS" ]]; then
            # Run addr2line and capture the output
            output=$(addr2line -f -e "$VMLINUX_FILE" "$address" 2>>"$ERROR_LOG")
            
            # Split addr2line output into function and file information
            function=$(echo "$output" | sed -n '1p') # First line is the function name
            file=$(echo "$output" | sed -n '2p')     # Second line is the file info

            echo "$address,$function,$file" | tee -a "$output_file"

            # Print results to run.log
            # echo "$file: $address,$function,$file_info" >> "$RUN_LOG"
        fi
    done < "$file"

    echo "Finished processing: $file" >> "$RUN_LOG"
}

# Export functions and variables for parallel background processes
export -f parse_file
export VMLINUX_FILE MIN_ADDRESS ERROR_LOG RUN_LOG OUTPUT_DIR

# Process files in parallel
for file in "$LOG_DIR"/batch*.raw; do
    parse_file "$file" &
done

# Wait for all background processes to finish
wait

echo "All files processed. Check $RUN_LOG and $ERROR_LOG for details." | tee -a "$RUN_LOG"












