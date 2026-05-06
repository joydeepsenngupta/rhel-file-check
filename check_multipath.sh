#!/bin/bash

# Configuration
INPUT_FILE="server_list.txt"
REPORT_FILE="multipath_audit_$(date +%F).log"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: $INPUT_FILE not found!"
    exit 1
fi

echo "Starting Audit on 2000+ servers..."
> "$REPORT_FILE" # This clears the file at the start

# Use a custom file descriptor (3) to avoid the SSH stdin conflict
while IFS= read -u 3 -r SERVER || [[ -n "$SERVER" ]]; do
    [[ -z "$SERVER" || "$SERVER" =~ ^# ]] && continue

    echo "Checking: $SERVER"
    
    # -n: Prevents SSH from reading the rest of the server list
    # -o ConnectTimeout: Stops the script from hanging on dead servers
    OUTPUT=$(ssh -n -o ConnectTimeout=5 -o BatchMode=yes -t "$SERVER" "sudo multipath -ll" 2>/dev/null)

    if [[ $? -eq 0 ]]; then
        # Format the output to 1.0.0 style as requested
        PATHS=$(echo "$OUTPUT" | grep -oE '[0-9]+:[0-9]+:[0-9]+' | sort -u | tr ':' '.')
        
        echo "[SERVER: $SERVER]" >> "$REPORT_FILE"
        if [[ -z "$PATHS" ]]; then
            echo "Status: No multipath devices." >> "$REPORT_FILE"
        else
            echo "Paths Found: $PATHS" >> "$REPORT_FILE"
        fi
    else
        echo "[SERVER: $SERVER] Status: FAILED" >> "$REPORT_FILE"
    fi
    echo "-----------------------------------" >> "$REPORT_FILE"

done 3< "$INPUT_FILE" # Redirect file to descriptor 3

echo "Audit complete. Results in $REPORT_FILE"
