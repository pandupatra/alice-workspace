#!/bin/bash

# Stock monitoring script for BUMI and DEWA
# Check every 30 minutes, alert if 3%+ change in 1 hour

STOCKS=("BUMI.JK" "DEWA.JK" "BSDE.JK" "PWON.JK" "CTRA.JK" "SMRA.JK" "LPKR.JK" "BMRI.JK" "BBNI.JK" "BBRI.JK" "BBTN.JK")
PRICE_FILE="/root/.openclaw/workspace/memory/stock-prices.json"
LOG_FILE="/root/.openclaw/workspace/memory/stock-monitor.log"
DISCORD_CHANNEL="1477857560492249268"

get_price() {
    local symbol=$1
    curl -s -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v8/finance/chart/${symbol}" | \
        python3 -c "import sys,json; data=json.load(sys.stdin); print(data['chart']['result'][0]['meta']['regularMarketPrice'])" 2>/dev/null
}

get_price_1h_ago() {
    local symbol=$1
    local now=$(date +%s)
    local hour_ago=$((now - 3600))
    
    # Get 1h historical data
    local range=$(curl -s -A "Mozilla/5.0" "https://query1.finance.yahoo.com/v8/finance/chart/${symbol}?range=1h&interval=1m" | \
        python3 -c "
import sys,json
data=json.load(sys.stdin)
timestamps = data['chart']['result'][0]['timestamp']
closes = data['chart']['result'][0]['indicators']['quote'][0]['close']
now = $now
hour_ago = $hour_ago

# Find closest to 1 hour ago
for i, ts in enumerate(timestamps):
    if ts <= hour_ago and i < len(closes):
        print(closes[i])
        break
" 2>/dev/null)
    
    echo "$range"
}

calculate_change() {
    local current=$1
    local old=$2
    
    if [ -z "$current" ] || [ -z "$old" ] || [ "$old" = "None" ]; then
        echo "0"
        return
    fi
    
    python3 -c "print(round((($current - $old) / $old) * 100, 2))"
}

send_alert() {
    local symbol=$1
    local change=$2
    local current=$3
    local old=$4
    
    local emoji=""
    if (( $(echo "$change > 0" | bc -l) )); then
        emoji="📈"
    else
        emoji="📉"
    fi
    
    local message="🚨 **Stock Alert** $emoji

**$symbol**
• Current: ₨$current
• 1h ago: ₨$old
• Change: $change%"
    
    openclaw message discord --channel $DISCORD_CHANNEL --message "$message" 2>/dev/null || \
    echo "$(date): ALERT $symbol $change%" >> $LOG_FILE
}

# Main loop
while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Checking stocks..." >> $LOG_FILE
    
    for symbol in "${STOCKS[@]}"; do
        current_price=$(get_price "$symbol")
        
        if [ -z "$current_price" ]; then
            echo "  $symbol: Failed to get price" >> $LOG_FILE
            continue
        fi
        
        # Get old price from file (1 hour ago reading)
        old_price=$(python3 -c "
import json, time
try:
    with open('$PRICE_FILE', 'r') as f:
        data = json.load(f)
    if '$symbol' in data:
        # Find price closest to 1 hour ago
        now = time.time()
        for entry in data['$symbol']:
            if now - entry['timestamp'] >= 3600:
                print(entry['price'])
                break
except: pass
" 2>/dev/null)
        
        if [ -n "$old_price" ] && [ "$old_price" != "None" ]; then
            change=$(calculate_change "$current_price" "$old_price")
            change_abs=$(echo "$change" | tr -d '-')
            
            echo "  $symbol: current=$current_price, 1h_ago=$old_price, change=$change%" >> $LOG_FILE
            
            # Alert if 3% or more
            is_over_3=$(echo "$change_abs >= 3" | bc -l 2>/dev/null)
            if [ "$is_over_3" = "1" ]; then
                send_alert "$symbol" "$change" "$current_price" "$old_price"
            fi
        else
            echo "  $symbol: first run, no baseline yet (price: $current_price)" >> $LOG_FILE
        fi
        
        # Update price log
        python3 -c "
import json, time
try:
    with open('$PRICE_FILE', 'r') as f:
        data = json.load(f)
except:
    data = {}

if '$symbol' not in data:
    data['$symbol'] = []

data['$symbol'].append({'timestamp': time.time(), 'price': $current_price})

# Keep only last 2 hours of data
now = time.time()
data['$symbol'] = [e for e in data['$symbol'] if now - e['timestamp'] < 7200]

with open('$PRICE_FILE', 'w') as f:
    json.dump(data, f)
" 2>/dev/null
    done
    
    # Wait 30 minutes
    sleep 1800
done
