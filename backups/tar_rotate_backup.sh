#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : tar_rotate_backup.sh
# Description : Creates timestamped tar.gz archives of a target directory,
#               generates SHA256 checksums, and rotates old backups.
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE_DIR=""
DEST_DIR=""
RETENTION_DAYS=7

usage() {
  echo "Usage: $0 -s <source_dir> -d <destination_dir> [OPTIONS]"
  echo "Options:"
  echo "  -s <path>     Source directory to back up (Required)"
  echo "  -d <path>     Destination directory to store archives (Required)"
  echo "  -r <days>     Keep backups for N days (Default: 7)"
  echo "  -h            Show help"
  exit 1
}

while getopts "s:d:r:h" opt; do
  case "$opt" in
    s) SOURCE_DIR="$OPTARG" ;;
    d) DEST_DIR="$OPTARG" ;;
    r) RETENTION_DAYS="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
  echo -e "${RED}Error: Source (-s) and Destination (-d) directories are required.${NC}"
  usage
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo -e "${RED}Error: Source directory '${SOURCE_DIR}' does not exist.${NC}"
  exit 1
fi

mkdir -p "$DEST_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FOLDER_NAME=$(basename "$SOURCE_DIR")
ARCHIVE_NAME="${FOLDER_NAME}_backup_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${DEST_DIR}/${ARCHIVE_NAME}"
CHECKSUM_PATH="${ARCHIVE_PATH}.sha256"

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}         Automated Backup & Rotation Tool            ${NC}"
echo -e "${BLUE}         Author: Sanjeev Senapati                    ${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo -e "Source       : ${SOURCE_DIR}"
echo -e "Destination  : ${DEST_DIR}"
echo -e "Retention    : ${RETENTION_DAYS} days\n"

# 1. Create Tarball
echo -e "${YELLOW}[1/3] Creating compressed archive...${NC}"
tar -czf "$ARCHIVE_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
echo -e "${GREEN}Created: ${ARCHIVE_PATH}${NC}"

# 2. Generate SHA256 Checksum
echo -e "${YELLOW}[2/3] Generating SHA256 checksum...${NC}"
if command -v shasum &>/dev/null; then
  shasum -a 256 "$ARCHIVE_PATH" > "$CHECKSUM_PATH"
elif command -v sha256sum &>/dev/null; then
  sha256sum "$ARCHIVE_PATH" > "$CHECKSUM_PATH"
fi
echo -e "${GREEN}Checksum created: ${CHECKSUM_PATH}${NC}"

# 3. Rotate Old Backups
echo -e "${YELLOW}[3/3] Purging backups older than ${RETENTION_DAYS} days...${NC}"
DELETED_COUNT=0
find "$DEST_DIR" -type f \( -name "*_backup_*.tar.gz" -o -name "*_backup_*.sha256" \) -mtime +"$RETENTION_DAYS" | while read -r old_file; do
  echo -e "${RED}Removing old backup file: ${old_file}${NC}"
  rm -f "$old_file"
  DELETED_COUNT=$((DELETED_COUNT + 1))
done

echo -e "\n${GREEN}Backup and rotation completed successfully!${NC}"
