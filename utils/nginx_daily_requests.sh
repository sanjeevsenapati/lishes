#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : nginx_daily_requests.sh
# Description : Aggregates daily request counts, HTTP status code breakdown,
#               unique visitor IPs, and throughput metrics (TPS - Requests/sec,
#               TPM - Requests/min) from plain or .gz Nginx log files.
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

# Stream logs (.gz vs plain text)
stream_logs() {
  for path in "${LOG_PATHS[@]}"; do
    if [ -d "$path" ]; then
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
echo -e "${BLUE}     Nginx Daily Request Traffic & TPS/TPM Analyzer  ${NC}"
echo -e "${BLUE}     Author: Sanjeev Senapati                        ${NC}"
echo -e "${BLUE}=====================================================${NC}\n"

stream_logs | awk '
BEGIN {
  printf "%-13s %-9s %-9s %-9s %-9s %-9s %-9s %-9s %-9s %-9s\n", 
    "DATE", "TOTAL", "2xx", "3xx", "4xx", "5xx", "AVG TPS", "PEAK TPS", "AVG TPM", "PEAK TPM"
  print "-----------------------------------------------------------------------------------------------------------------"
}
{
  # Extract timestamp: [23/Aug/2026:20:00:15 +0530]
  match($0, /\[[0-9]{2}\/[A-Za-z]{3}\/[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2}/)
  if (RSTART > 0) {
    full_ts = substr($0, RSTART + 1, RLENGTH - 1)
    
    # Extract components
    date_str = substr(full_ts, 1, 11)        # 23/Aug/2026
    minute_str = substr(full_ts, 1, 17)      # 23/Aug/2026:20:00
    sec_str = full_ts                        # 23/Aug/2026:20:00:15
    ip = $1

    # Extract status code
    match($0, /" [0-9]{3} /)
    status = 0
    if (RSTART > 0) {
      status = substr($0, RSTART + 2, 3)
    }

    dates[date_str]++
    total_count++

    # Track Per-Second (TPS) and Per-Minute (TPM) buckets
    sec_buckets[sec_str]++
    min_buckets[minute_str]++

    if (sec_buckets[sec_str] > peak_tps[date_str]) {
      peak_tps[date_str] = sec_buckets[sec_str]
    }
    if (min_buckets[minute_str] > peak_tpm[date_str]) {
      peak_tpm[date_str] = min_buckets[minute_str]
    }

    # Unique IPs per day
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

    tot = dates[d]
    avg_tps = tot / 86400.0
    avg_tpm = tot / 1440.0
    ptps = (d in peak_tps) ? peak_tps[d] : 0
    ptpm = (d in peak_tpm) ? peak_tpm[d] : 0

    printf "%-13s %-9d %-9d %-9d %-9d %-9d %-9.2f %-9d %-9.2f %-9d\n", 
      d, tot, s2, s3, s4, s5, avg_tps, ptps, avg_tpm, ptpm
  }

  print "-----------------------------------------------------------------------------------------------------------------"
  printf "TOTAL REQUESTS PROCESSED: %d\n", total_count
}
' | sort -k1.8,1.11n -k1.4,1.6M -k1.1,1.2n
