#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : log_cleaner.sh
# Description : Utility to find, compress, or clean old log files beyond a set
#               retention age or size threshold with dry-run support.
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_DIR=""
DAYS_OLD=7
COMPRESS=false
DELETE=false
DRY_RUN=true

usage() {
  echo "Usage: $0 -p <log_path> [OPTIONS]"
  echo "Options:"
  echo "  -p <path>     Directory path containing log files (Required)"
  echo "  -d <days>     Files older than N days (Default: 7)"
  echo "  -c            Compress matching .log files into .gz"
  echo "  -x            Delete matching old .log / .gz files"
  echo "  -f            Execute real cleanup (Default is Dry-Run mode)"
  echo "  -h            Show help"
  echo ""
  echo "Example:"
  echo "  $0 -p /var/log/app -d 14 -c -f     # Compress logs older than 14 days"
  echo "  $0 -p /var/log/app -d 30 -x -f     # Delete logs older than 30 days"
  exit 1
}

while getopts "p:d:cxfh" opt; do
  case "$opt" in
    p) TARGET_DIR="$OPTARG" ;;
    d) DAYS_OLD="$OPTARG" ;;
    c) COMPRESS=true ;;
    x) DELETE=true ;;
    f) DRY_RUN=false ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  echo -e "${RED}Error: Target directory (-p) is required.${NC}"
  usage
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}Error: Directory '${TARGET_DIR}' does not exist.${NC}"
  exit 1
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}              Log Maintenance & Cleanup Tool          ${NC}"
echo -e "${BLUE}              Author: Sanjeev Senapati               ${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo -e "Target Directory : ${TARGET_DIR}"
echo -e "Age Threshold    : > ${DAYS_OLD} days"
if [ "$DRY_RUN" = true ]; then
  echo -e "Mode             : ${YELLOW}DRY-RUN (No files will be modified)${NC}\n"
else
  echo -e "Mode             : ${RED}EXECUTE (Files WILL be compressed/deleted)${NC}\n"
fi

# Find files older than DAYS_OLD
if [ "$COMPRESS" = true ]; then
  echo -e "${YELLOW}--- Compressing .log files older than ${DAYS_OLD} days ---${NC}"
  find "$TARGET_DIR" -type f -name "*.log" -mtime +"$DAYS_OLD" | while read -r file; do
    if [ "$DRY_RUN" = true ]; then
      echo -e "[DRY-RUN] Would gzip: $file"
    else
      echo -e "${GREEN}[COMPRESSING] $file${NC}"
      gzip "$file"
    fi
  done
fi

if [ "$DELETE" = true ]; then
  echo -e "${YELLOW}--- Deleting files older than ${DAYS_OLD} days ---${NC}"
  find "$TARGET_DIR" -type f \( -name "*.log" -o -name "*.gz" -o -name "*.log.*" \) -mtime +"$DAYS_OLD" | while read -r file; do
    if [ "$DRY_RUN" = true ]; then
      echo -e "[DRY-RUN] Would delete: $file"
    else
      echo -e "${RED}[DELETING] $file${NC}"
      rm -f "$file"
    fi
  done
fi

if [ "$COMPRESS" = false ] && [ "$DELETE" = false ]; then
  echo -e "${YELLOW}No action (-c or -x) specified. Listing matching files older than ${DAYS_OLD} days:${NC}"
  find "$TARGET_DIR" -type f -name "*.log" -mtime +"$DAYS_OLD" -exec ls -lh {} \;
fi

echo -e "\n${GREEN}Log maintenance process completed.${NC}"
