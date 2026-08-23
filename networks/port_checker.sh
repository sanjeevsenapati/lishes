#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : port_checker.sh
# Description : Tests TCP connectivity, port availability, and connection latency
#               for specified host(s) and port(s).
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HOST=""
PORT=""
TIMEOUT=3

usage() {
  echo "Usage: $0 -h <host> -p <port> [OPTIONS]"
  echo "Options:"
  echo "  -h <host>     Target hostname or IP address (Required)"
  echo "  -p <port>     Target TCP port (Required)"
  echo "  -t <seconds>  Connection timeout in seconds (Default: 3)"
  echo "  -help         Show help"
  exit 1
}

while getopts "h:p:t:" opt; do
  case "$opt" in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    t) TIMEOUT="$OPTARG" ;;
    *) usage ;;
  esac
done

if [ -z "$HOST" ] || [ -z "$PORT" ]; then
  echo -e "${RED}Error: Target host (-h) and port (-p) are required.${NC}"
  usage
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}          TCP Connectivity & Latency Checker         ${NC}"
echo -e "${BLUE}          Author: Sanjeev Senapati                   ${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo -e "Testing Connection to ${YELLOW}${HOST}:${PORT}${NC} (Timeout: ${TIMEOUT}s)...\n"

# Method 1: nc (netcat) if available
if command -v nc &>/dev/null; then
  START_TIME=$(date +%s%N 2>/dev/null || date +%s)
  if nc -z -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null; then
    END_TIME=$(date +%s%N 2>/dev/null || date +%s)
    if [ ${#START_TIME} -gt 10 ]; then
      DIFF=$(( (END_TIME - START_TIME) / 1000000 ))
      LATENCY="${DIFF} ms"
    else
      LATENCY="< 1s"
    fi
    echo -e "${GREEN}[SUCCESS] Port ${PORT} on host '${HOST}' is OPEN! (Latency: ${LATENCY})${NC}"
  else
    echo -e "${RED}[FAILED] Port ${PORT} on host '${HOST}' is CLOSED or FILTERED (Connection Timed Out).${NC}"
  fi
# Method 2: bash built-in /dev/tcp fallback
elif command -v timeout &>/dev/null; then
  if timeout "$TIMEOUT" bash -c "</dev/tcp/${HOST}/${PORT}" 2>/dev/null; then
    echo -e "${GREEN}[SUCCESS] Port ${PORT} on host '${HOST}' is OPEN!${NC}"
  else
    echo -e "${RED}[FAILED] Port ${PORT} on host '${HOST}' is CLOSED or UNREACHABLE.${NC}"
  fi
else
  echo -e "${YELLOW}Warning: netcat (nc) not found, using basic ping/curl test.${NC}"
  if curl -s --connect-timeout "$TIMEOUT" "${HOST}:${PORT}" &>/dev/null; then
    echo -e "${GREEN}[SUCCESS] Port ${PORT} on host '${HOST}' responded.${NC}"
  else
    echo -e "${RED}[FAILED] Could not connect to ${HOST}:${PORT}.${NC}"
  fi
fi
