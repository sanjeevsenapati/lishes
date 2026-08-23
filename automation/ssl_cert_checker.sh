#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : ssl_cert_checker.sh
# Description : Checks SSL/TLS certificate expiration dates for remote domains
#               or local PEM files and alerts if expiring soon.
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

WARNING_DAYS=30

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  -d <domain>        Single domain name to check (e.g., example.com)"
  echo "  -p <port>          Port number (default: 443)"
  echo "  -f <domain_file>   File containing list of domains (one per line)"
  echo "  -w <days>          Warning threshold in days (default: 30)"
  echo "  -h                 Show this help message"
  exit 1
}

DOMAIN=""
PORT=443
DOMAIN_FILE=""

while getopts "d:p:f:w:h" opt; do
  case "$opt" in
    d) DOMAIN="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    f) DOMAIN_FILE="$OPTARG" ;;
    w) WARNING_DAYS="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [ -z "$DOMAIN" ] && [ -z "$DOMAIN_FILE" ]; then
  echo -e "${YELLOW}No domain or file provided. Defaulting to domain check: google.com${NC}\n"
  DOMAIN="google.com"
fi

check_domain_ssl() {
  local target_domain="$1"
  local target_port="$2"

  echo -n "Checking ${target_domain}:${target_port}... "

  # Extract expiry date using openssl
  EXPIRY_DATE=$(echo | openssl s_client -servername "${target_domain}" -connect "${target_domain}:${target_port}" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

  if [ -z "$EXPIRY_DATE" ]; then
    echo -e "${RED}[ERROR] Unable to retrieve certificate.${NC}"
    return 1
  fi

  # Convert dates to seconds since epoch
  if [[ "$(uname)" == "Darwin" ]]; then
    EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$EXPIRY_DATE" "+%s" 2>/dev/null || date -j -f "%b %e %T %Y %Z" "$EXPIRY_DATE" "+%s" 2>/dev/null)
  else
    EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" "+%s")
  fi

  CURRENT_EPOCH=$(date "+%s")
  SECONDS_LEFT=$((EXPIRY_EPOCH - CURRENT_EPOCH))
  DAYS_LEFT=$((SECONDS_LEFT / 86400))

  if [ "$DAYS_LEFT" -lt 0 ]; then
    echo -e "${RED}[EXPIRED] Expired $((DAYS_LEFT * -1)) days ago on ${EXPIRY_DATE}${NC}"
  elif [ "$DAYS_LEFT" -le "$WARNING_DAYS" ]; then
    echo -e "${YELLOW}[WARNING] Expires in ${DAYS_LEFT} days on ${EXPIRY_DATE}${NC}"
  else
    echo -e "${GREEN}[OK] Valid for ${DAYS_LEFT} days (Expires: ${EXPIRY_DATE})${NC}"
  fi
}

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}           SSL/TLS Certificate Expiry Checker        ${NC}"
echo -e "${BLUE}           Author: Sanjeev Senapati                  ${NC}"
echo -e "${BLUE}=====================================================${NC}"

if [ -n "$DOMAIN" ]; then
  check_domain_ssl "$DOMAIN" "$PORT"
fi

if [ -n "$DOMAIN_FILE" ]; then
  if [ ! -f "$DOMAIN_FILE" ]; then
    echo -e "${RED}File not found: ${DOMAIN_FILE}${NC}"
    exit 1
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    check_domain_ssl "$line" "$PORT"
  done < "$DOMAIN_FILE"
fi
