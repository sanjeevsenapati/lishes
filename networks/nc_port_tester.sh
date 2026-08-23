#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : nc_port_tester.sh
# Description : Pre-deployment port & firewall connectivity verification tool.
#               Runs in Server (listener) mode or Client (prober) mode using Netcat (nc)
#               to test network routing before real application deployment.
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

MODE=""
PORT=""
HOST="127.0.0.1"
PROTOCOL="tcp"
TIMEOUT=5

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Modes (Select one):"
  echo "  -l, --listen <port>      Start in SERVER (listener) mode on specified port"
  echo "  -c, --connect <host>     Start in CLIENT mode to test connection to target host"
  echo ""
  echo "Options:"
  echo "  -p, --port <port>        Target port (Required in client mode)"
  echo "  -u, --udp                Use UDP protocol instead of TCP (Default: TCP)"
  echo "  -t, --timeout <sec>      Connection timeout in seconds (Default: 5s)"
  echo "  -h, --help               Show this help message"
  echo ""
  echo "Examples:"
  echo "  # Step 1: On Server A (Target App Node), start listener:"
  echo "  $0 -l 8080"
  echo ""
  echo "  # Step 2: On Server B (Client Node), verify connectivity:"
  echo "  $0 -c 192.168.1.100 -p 8080"
  exit 1
}

if ! command -v nc &>/dev/null; then
  echo -e "${RED}Error: Netcat (nc) utility is not installed.${NC}"
  exit 1
fi

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--listen)
      MODE="server"
      PORT="$2"
      shift 2
      ;;
    -c|--connect)
      MODE="client"
      HOST="$2"
      shift 2
      ;;
    -p|--port)
      PORT="$2"
      shift 2
      ;;
    -u|--udp)
      PROTOCOL="udp"
      shift
      ;;
    -t|--timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$MODE" ] || [ -z "$PORT" ]; then
  echo -e "${RED}Error: Mode (-l or -c) and Port (-p or -l) are required.${NC}\n"
  usage
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}     Pre-Deployment Network Port Tester (Netcat)     ${NC}"
echo -e "${BLUE}     Author: Sanjeev Senapati                        ${NC}"
echo -e "${BLUE}=====================================================${NC}"

NC_FLAGS=""
if [ "$PROTOCOL" = "udp" ]; then
  NC_FLAGS="-u"
fi

if [ "$MODE" = "server" ]; then
  echo -e "${GREEN}[SERVER MODE]${NC} Starting dummy application listener on ${MAGENTA}${PROTOCOL}/${PORT}${NC}..."
  echo -e "${YELLOW}Press Ctrl+C to stop listener.${NC}\n"

  # Detect OS flavor for Netcat syntax (-l -p vs -l)
  if nc -h 2>&1 | grep -q '\-p'; then
    echo -e "Listening for incoming pre-deployment test traffic..."
    nc $NC_FLAGS -l -p "$PORT"
  else
    echo -e "Listening for incoming pre-deployment test traffic..."
    nc $NC_FLAGS -l "$PORT"
  fi

elif [ "$MODE" = "client" ]; then
  echo -e "${GREEN}[CLIENT MODE]${NC} Testing ${PROTOCOL} connectivity to ${MAGENTA}${HOST}:${PORT}${NC} (Timeout: ${TIMEOUT}s)..."

  # Test TCP/UDP probe
  if [ "$PROTOCOL" = "tcp" ]; then
    if nc -z -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null; then
      echo -e "\n${GREEN}[SUCCESS] Pre-Deployment Check PASSED!${NC}"
      echo -e "${GREEN}Port ${PORT} on ${HOST} is REACHABLE and accepting connections.${NC}"
      echo -e "${GREEN}Firewall / Security Group rules are correctly configured.${NC}"
    else
      echo -e "\n${RED}[FAILED] Pre-Deployment Check FAILED!${NC}"
      echo -e "${RED}Port ${PORT} on ${HOST} is UNREACHABLE or BLOCKED.${NC}"
      echo -e "${YELLOW}Troubleshooting Tips:${NC}"
      echo "  1. Ensure listener is running on ${HOST}: ./nc_port_tester.sh -l ${PORT}"
      echo "  2. Check firewall/iptables/ufw rules on target host."
      echo "  3. Check AWS/GCP/Azure Security Groups and Network ACLs."
      exit 1
    fi
  else
    # UDP probe test
    if nc -z -u -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null; then
      echo -e "\n${GREEN}[SUCCESS] UDP Port ${PORT} on ${HOST} is open/reachable.${NC}"
    else
      echo -e "\n${RED}[FAILED] UDP Port ${PORT} on ${HOST} did not respond.${NC}"
      exit 1
    fi
  fi
fi
