#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : system_health_check.sh
# Description : Provides a quick health dashboard including CPU, RAM, Disk,
#               Top Processes, Open Ports, and Failed System Services.
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

OS_TYPE=$(uname)

print_header() {
  echo -e "\n${BLUE}=====================================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}=====================================================${NC}"
}

echo -e "${GREEN}System Health Report - $(date)${NC}"
echo "Hostname : $(hostname)"
echo "OS Type  : ${OS_TYPE}"
echo "Uptime   : $(uptime | sed 's/.*up \([^,]*\), .*/\1/')"
echo "Kernel   : $(uname -r)"

# 1. CPU Load Average
print_header "1. CPU Load Average"
if [ -f /proc/loadavg ]; then
  LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
  echo -e "Load Average (1m, 5m, 15m): ${YELLOW}${LOAD}${NC}"
else
  uptime | awk -F'load average:' '{ print "Load Average:" $2 }' | xargs
fi

# 2. Memory Usage
print_header "2. Memory Usage"
if command -v free &>/dev/null; then
  free -h
elif command -v vm_stat &>/dev/null; then
  vm_stat | head -n 6
fi

# 3. Disk Usage Overview
print_header "3. Disk Usage (Root & Key Mounts)"
df -h /

# 4. Top 5 CPU Consuming Processes
print_header "4. Top 5 Processes by CPU Usage"
if [[ "$OS_TYPE" == "Darwin" ]]; then
  ps -Eo pid,user,%cpu,%mem,command -r | head -n 6
else
  ps -eo pid,user,%cpu,%mem,command --sort=-%cpu | head -n 6
fi

# 5. Top 5 Memory Consuming Processes
print_header "5. Top 5 Processes by Memory Usage"
if [[ "$OS_TYPE" == "Darwin" ]]; then
  ps -Eo pid,user,%cpu,%mem,command -m | head -n 6
else
  ps -eo pid,user,%cpu,%mem,command --sort=-%mem | head -n 6
fi

# 6. Failed Systemd Services (Linux only)
if command -v systemctl &>/dev/null; then
  print_header "6. Failed Systemd Services"
  FAILED_SERVICES=$(systemctl --failed --no-legend)
  if [ -z "$FAILED_SERVICES" ]; then
    echo -e "${GREEN}No failed services found.${NC}"
  else
    echo -e "${RED}${FAILED_SERVICES}${NC}"
  fi
fi

# 7. Active Listening Ports
print_header "7. Active Listening TCP Ports"
if command -v ss &>/dev/null; then
  ss -tulpn | head -n 10
elif command -v lsof &>/dev/null; then
  lsof -iTCP -sTCP:LISTEN -P -n | head -n 10
elif command -v netstat &>/dev/null; then
  netstat -an | grep LISTEN | head -n 10
fi

echo -e "\n${GREEN}Health check completed successfully.${NC}"
