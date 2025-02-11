#!/bin/bash

# Thresholds
THRESHOLD_ORANGE=70
THRESHOLD_RED=80

# ANSI escape codes for colors
RED='\033[0;31m'
ORANGE='\033[0;33m' # Orange-like color
NC='\033[0m' # No Color

echo "Disk Usage Report"
echo "-------------------------"

# Detect OS
OS_TYPE=$(uname)

if [[ "$OS_TYPE" == "Darwin" ]]; then
  # macOS-specific df command and processing
  df -H | awk 'NR>1 {print $1, $5, $9}' | while read -r filesystem usage mountpoint; do
    if [[ "$usage" == *"%"* ]]; then
      usage_value=${usage%\%}
      if [[ "$usage_value" -ge "$THRESHOLD_RED" ]]; then
        echo "${RED}${mountpoint} (${filesystem}) - ${usage}${NC}"
      elif [[ "$usage_value" -ge "$THRESHOLD_ORANGE" ]]; then
        echo "${ORANGE}${mountpoint} (${filesystem}) - ${usage}${NC}"
      else
        echo "${mountpoint} (${filesystem}) - ${usage}"
      fi
    fi
  done
else
  # Linux-specific df command and processing
  df -h --output=target,pcent | tail -n +2 | while read -r mountpoint usage; do
    usage_value=${usage%\%}
    if [[ "$usage_value" =~ ^[0-9]+$ ]]; then
      if [[ "$usage_value" -ge "$THRESHOLD_RED" ]]; then
        echo "${RED}${mountpoint} - ${usage}${NC}"
      elif [[ "$usage_value" -ge "$THRESHOLD_ORANGE" ]]; then
        echo "${ORANGE}${mountpoint} - ${usage}${NC}"
      else
        echo "${mountpoint} - ${usage}"
      fi
    fi
  done
fi
