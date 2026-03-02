#!/bin/bash

# Background script to run trending report at 4AM daily
# Checks every minute if it's 4:00 AM

SCRIPT_DIR="/root/.openclaw/workspace/scripts"
LOG_FILE="/root/.openclaw/workspace/memory/trending-cron.log"
LAST_RUN_FILE="/root/.openclaw/workspace/memory/trending-last-run"

echo "$(date): Trending report scheduler started" >> "$LOG_FILE"

while true; do
    current_hour=$(date +%H)
    current_minute=$(date +%M)
    current_date=$(date +%Y-%m-%d)
    
    # Check if it's 4:00 AM
    if [ "$current_hour" = "04" ] && [ "$current_minute" = "00" ]; then
        # Check if we already ran today
        last_run=$(cat "$LAST_RUN_FILE" 2>/dev/null)
        
        if [ "$last_run" != "$current_date" ]; then
            echo "$(date): Running trending report..." >> "$LOG_FILE"
            cd "$SCRIPT_DIR"
            ./trending-report.sh >> "$LOG_FILE" 2>&1
            echo "$current_date" > "$LAST_RUN_FILE"
            echo "$(date): Report sent!" >> "$LOG_FILE"
        fi
    fi
    
    # Check every minute
    sleep 60
done
