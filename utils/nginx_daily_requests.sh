#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : nginx_daily_requests.sh
# Description : Aggregates and prints daily request counts, HTTP status breakdown
#               (2xx, 3xx, 4xx, 5xx), and unique visitor IPs from plain or .gz
#               Nginx log files.
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

LOG_PATHS=()

usage() {
  echo "Usage: $0 [LOG_FILE | DIR | *.gz ...]"
  echo ""
  echo "Examples:"
  echo "  $0 /var/log/nginx/access.log"
  echo "  $0 /var/log/nginx/access.log*.gz"
  echo "  $0 /var/log/nginx/"
  exit 1
}

if [ $# -eq 0 ]; then
  if [ -d "/var/log/nginx" ]; then
    echo -e "${YELLOW}No log path provided. Defaulting to /var/log/nginx/${NC}"
    LOG_PATHS+=("/var/log/nginx")
  else
    usage
  fi
else
  for arg in "$@"; do
    LOG_PATHS+=("$arg")
  done
fi

# Function to reader stream (.gz vs plain)
stream_logs() {
  for path in "${LOG_PATHS[@]}"; do
    if [ -d "$path" ]; then
      # Find plain and .gz files in directory
      find "$path" -type f \( -name "*.log" -o -name "*.log*.gz" -o -name "access*" \) | while read -r f; do
        if [[ "$f" == *.gz ]]; then
          gzip -dc "$f" 2>/dev/null || true
        else
          cat "$f" 2>/dev/null || true
        fi
      done
    elif [ -f "$path" ]; then
      if [[ "$path" == *.gz ]]; then
        gzip -dc "$path" 2>/dev/null || true
      else
        cat "$path" 2>/dev/null || true
      fi
    fi
  done
}

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}         Nginx Daily Request Traffic Analyzer        ${NC}"
echo -e "${BLUE}         Author: Sanjeev Senapati                    ${NC}"
echo -e "${BLUE}=====================================================${NC}\n"

# Process stream via AWK
stream_logs | awk '
BEGIN {
  printf "%-15s %-12s %-10s %-10s %-10s %-10s %-12s\n", "DATE", "TOTAL REQS", "2xx (OK)", "3xx (REDIR)", "4xx (CLIENT)", "5xx (SERVER)", "UNIQUE IPs"
  print "----------------------------------------------------------------------------------------"
}
{
  # Extract timestamp [23/Aug/2026:20:00:00 +0530]
  match($0, /\[[0-9]{2}\/[A-Za-z]{3}\/[0-9]{4}/)
  if (RSTART > 0) {
    date_str = substr($0, RSTART + 1, RLENGTH - 1)
    ip = $1

    # Extract status code
    match($0, /" [0-9]{3} /)
    status = 0
    if (RSTART > 0) {
      status = substr($0, RSTART + 2, 3)
    }

    dates[date_str]++
    total_count++

    # Track Unique IPs per date
    ip_key = date_str " " ip
    if (!(ip_key in unique_ips)) {
      unique_ips[ip_key] = 1
      unique_ip_count[date_str]++
    }

    if (status >= 200 && status < 300) status_2xx[date_str]++
    else if (status >= 300 && status < 400) status_3xx[date_str]++
    else if (status >= 400 && status < 500) status_4xx[date_str]++
    else if (status >= 500) status_5xx[date_str]++
  }
}
END {
  if (total_count == 0) {
    print "No valid Nginx log records found."
    exit
  }

  for (d in dates) {
    s2 = (d in status_2xx) ? status_2xx[d] : 0
    s3 = (d in status_3xx) ? status_3xx[d] : 0
    s4 = (d in status_4xx) ? status_4xx[d] : 0
    s5 = (d in status_5xx) ? status_5xx[d] : 0
    uip = (d in unique_ip_count) ? unique_ip_count[d] : 0

    printf "%-15s %-12d %-10d %-10d %-10d %-10d %-12d\n", d, dates[d], s2, s3, s4, s5, uip
  }

  print "----------------------------------------------------------------------------------------"
  printf "TOTAL REQUESTS PROCESSED: %d\n", total_count
}
' | sort -k1.8,1.11n -k1.4,1.6M -k1.1,1.2n
