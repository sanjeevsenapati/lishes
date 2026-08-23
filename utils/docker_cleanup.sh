#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : docker_cleanup.sh
# Description : DevOps helper to prune stopped containers, dangling images,
#               unused volumes, and build caches to reclaim disk space.
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FORCE=false

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  -f    Force clean without interactive confirmation prompt"
  echo "  -a    Clean all unused images (not just dangling ones)"
  echo "  -v    Also prune unused volumes"
  echo "  -h    Show help message"
  exit 1
}

ALL_IMAGES=false
PRUNE_VOLUMES=false

while getopts "favh" opt; do
  case "$opt" in
    f) FORCE=true ;;
    a) ALL_IMAGES=true ;;
    v) PRUNE_VOLUMES=true ;;
    h) usage ;;
    *) usage ;;
  esac
done

if ! command -v docker &>/dev/null; then
  echo -e "${RED}Error: Docker is not installed or not in PATH.${NC}"
  exit 1
fi

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}            Docker System Cleanup Utility            ${NC}"
echo -e "${BLUE}            Author: Sanjeev Senapati                 ${NC}"
echo -e "${BLUE}=====================================================${NC}"

echo -e "${YELLOW}Current Docker Disk Usage:${NC}"
docker system df 2>/dev/null || true
echo ""

if [ "$FORCE" = false ]; then
  read -p "Are you sure you want to prune unused Docker resources? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cleanup cancelled."
    exit 0
  fi
fi

echo -e "${YELLOW}[1/4] Removing stopped containers...${NC}"
docker container prune -f

echo -e "${YELLOW}[2/4] Removing dangling/unused images...${NC}"
if [ "$ALL_IMAGES" = true ]; then
  docker image prune -a -f
else
  docker image prune -f
fi

if [ "$PRUNE_VOLUMES" = true ]; then
  echo -e "${YELLOW}[3/4] Removing unused volumes...${NC}"
  docker volume prune -f
else
  echo -e "${YELLOW}[3/4] Skipping volume prune (use -v flag to enable)${NC}"
fi

echo -e "${YELLOW}[4/4] Pruning build cache...${NC}"
docker builder prune -f 2>/dev/null || true

echo -e "\n${GREEN}Cleanup Complete. Updated Docker Disk Usage:${NC}"
docker system df 2>/dev/null || true
