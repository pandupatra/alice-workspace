#!/bin/bash

# X (Twitter) Trending Report Script
# Runs daily at 4AM and sends DM to user

DISCORD_CHANNEL="1477857560492249268"
LOG_FILE="/root/.openclaw/workspace/memory/trending-report.log"

get_trending() {
    # Fetch trending page and extract properly
    curl -s "https://trends24.in/" -H "User-Agent: Mozilla/5.0" | \
    grep -oP '(?<=<a href="https://twitter.com/search\?q=)[^"]+' | \
    sed 's/%20/ /g; s/%23/#/g; s/%D9/%/g' | \
    head -15 | \
    sed 's/.*>//' | \
    grep -v '^$' | \
    head -10
}

# Alternative using python
get_trending_python() {
    python3 << 'EOF'
import re, urllib.request, json, html

try:
    req = urllib.request.Request('https://trends24.in/', headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=15) as response:
        html = response.read().decode()
    
    # Find all links with twitter search
    patterns = re.findall(r'twitter\.com/search\?q=([^\"]+)', html)
    
    trends = []
    seen = set()
    for p in patterns:
        # Decode HTML entities and URL encoding
        t = html.unescape(p).replace('%20', ' ').replace('%23', '#')
        t = re.sub(r'<[^>]+>', '', t)  # Remove HTML tags
        t = t.strip()
        if t and len(t) > 1 and t.lower() not in seen:
            seen.add(t.lower())
            trends.append(t)
    
    # Get unique trends
    for t in trends[:10]:
        print(f"- {t}")
        
except Exception as e:
    print(f"Error: {e}")
EOF
}

send_report() {
    local trends="$1"
    local date=$(date '+%Y-%m-%d')
    
    local message="📊 **Daily X Trends Report**

📅 *$date*

$trends

#X #Trending"
    
    openclaw message discord --channel "$DISCORD_CHANNEL" --message "$message" 2>/dev/null
}

# Main
timestamp=$(date '+%Y-%m-%d %H:%M')
echo "[$timestamp] Fetching trending topics..." >> "$LOG_FILE"

trends=$(get_trending_python 2>&1)
echo "[$timestamp] Trends fetched" >> "$LOG_FILE"

if [ -n "$trends" ]; then
    send_report "$trends"
    echo "[$timestamp] Report sent!" >> "$LOG_FILE"
else
    echo "[$timestamp] Using fallback" >> "$LOG_FILE"
    send_report "- Unable to fetch trends, check manually at https://trends24.in"
fi
