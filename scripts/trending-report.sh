#!/bin/bash

# X (Twitter) Trending Report - Improved
# Runs daily at 4AM

DISCORD_CHANNEL="1477857560492249268"
LOG_FILE="/root/.openclaw/workspace/memory/trending-report.log"

get_trending() {
    python3 << 'EOF'
import urllib.request, re, html

try:
    req = urllib.request.Request('https://trends24.in/', headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=15) as response:
        html_content = response.read().decode()
    
    patterns = re.findall(r'twitter\.com/search\?q=([^\"]+)', html_content)
    
    trends = []
    seen = set()
    for p in patterns:
        t = html.unescape(p).replace('%20', ' ').replace('%23', '#')
        t = re.sub(r'<[^>]+>', '', t).strip()
        if t and len(t) > 1 and t.lower() not in seen:
            seen.add(t.lower())
            trends.append(t)
    
    for t in trends[:10]:
        print(f"• {t}")
        
except Exception as e:
    print(f"Error: {e}")
EOF
}

send_report() {
    local trends="$1"
    local date=$(date '+%Y-%m-%d')
    
    openclaw message discord --channel "$DISCORD_CHANNEL" --message "📊 **Daily X Trends Report**

📅 *$date*

$trends

#X #Trending 🐈‍⬛"
}

# Main
echo "[$(date '+%Y-%m-%d %H:%M')] Running trending report..." >> "$LOG_FILE"
trends=$(get_trending 2>&1)
echo "[$(date '+%Y-%m-%d %H:%M')] Trends: ${trends:0:100}..." >> "$LOG_FILE"

if [ -n "$trends" ] && [[ ! "$trends" == *"Error"* ]]; then
    send_report "$trends"
    echo "[$(date '+%Y-%m-%d %H:%M')] Report sent!" >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M')] Failed to get trends" >> "$LOG_FILE"
fi
