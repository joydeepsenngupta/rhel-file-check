#!/bin/bash

# Define the input file (ensure this file exists in the same directory)
INPUT_FILE="server_list.txt"
REPORT_FILE="multipath_audit_$(date +%F).log"

# Check if the input file exists before starting
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: $INPUT_FILE not found!"
    exit 1
fi

echo "Starting Multipath Audit..."
echo "Report: $REPORT_FILE"
echo "=====================================================" > "$REPORT_FILE"

# Read the file line by line
while IFS= read -r SERVER || [[ -n "$SERVER" ]]; do
    # Skip empty lines or commented lines
    [[ -z "$SERVER" || "$SERVER" =~ ^# ]] && continue

    echo "Processing: $SERVER"
    echo "[SERVER: $SERVER]" >> "$REPORT_FILE"

    # Execute the check
    # We use 'multipath -ll' and filter for the H:C:T:L patterns (e.g., 1:0:0:1)
    # The 'timeout' command prevents the script from hanging on unresponsive IPs
    OUTPUT=$(ssh -o ConnectTimeout=5 -o BatchMode=yes -t "$SERVER" "sudo multipath -ll" 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        # Grab the specific path combinations (the 1.0.0 or 1.0.1 style IDs)
        # We replace the colons with dots to match your requested format
        PATHS=$(echo "$OUTPUT" | grep -oE '[0-9]+:[0-9]+:[0-9]+' | sort -u | tr ':' '.')
        
        if [[ -z "$PATHS" ]]; then
            echo "Status: No multipath devices found." >> "$REPORT_FILE"
        else
            echo "Detected Path Combinations:" >> "$REPORT_FILE"
            echo "$PATHS" >> "$REPORT_FILE"
        fi
    else
        echo "Status: CONNECTION FAILED (Check SSH/Sudo permissions)" >> "$REPORT_FILE"
    fi

    echo "-----------------------------------------------------" >> "$REPORT_FILE"

done < "$INPUT_FILE"

echo "Done! Check $REPORT_FILE for the details."
