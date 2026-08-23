#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name : nginx_log_viewer.sh
# Description : Parses and renders Nginx access logs and Nginx WAF/Firewall
#               log formats with vibrant AWK-powered color highlighting.
# Author      : Sanjeev Senapati
# -----------------------------------------------------------------------------

set -e

MODE="auto"
LOG_FILE=""

usage() {
  echo "Usage: $0 [OPTIONS] [LOG_FILE]"
  echo ""
  echo "Options:"
  echo "  -m, --mode <auto|access|firelog>  Select log format parser (Default: auto)"
  echo "  -f, --file <file_path>           Path to Nginx log file (or pipe via stdin)"
  echo "  -h, --help                       Display this help message"
  echo ""
  echo "Examples:"
  echo "  tail -f /var/log/nginx/access.log | $0"
  echo "  $0 -f /var/log/nginx/access.log"
  echo "  $0 -m firelog -f /var/log/nginx/waf_firelog.log"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--mode)
      MODE="$2"
      shift 2
      ;;
    -f|--file)
      LOG_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [ -z "$LOG_FILE" ] && [ -f "$1" ]; then
        LOG_FILE="$1"
        shift
      else
        echo "Unknown option or invalid file: $1"
        usage
      fi
      ;;
  esac
done

awk -v mode="$MODE" '
BEGIN {
  # Color Palette Setup
  RESET   = "\033[0m"
  BOLD    = "\033[1m"
  RED     = "\033[0;31m"
  GREEN   = "\033[0;32m"
  YELLOW  = "\033[1;33m"
  BLUE    = "\033[0;34m"
  MAGENTA = "\033[0;35m"
  CYAN    = "\033[0;36m"
  WHITE   = "\033[1;37m"
  BG_RED  = "\033[41;1;37m"
  BG_GRN  = "\033[42;1;37m"
  DIM     = "\033[2m"
}

# Function to colorize status code
function color_status(status) {
  if (status >= 200 && status < 300) return GREEN BOLD status RESET
  if (status >= 300 && status < 400) return CYAN status RESET
  if (status >= 400 && status < 500) return YELLOW BOLD status RESET
  if (status >= 500) return RED BOLD status RESET
  return WHITE status RESET
}

# Function to colorize HTTP method
function color_method(method) {
  if (method == "GET") return GREEN BOLD method RESET
  if (method == "POST") return YELLOW BOLD method RESET
  if (method == "PUT" || method == "PATCH") return BLUE BOLD method RESET
  if (method == "DELETE") return RED BOLD method RESET
  if (method == "HEAD" || method == "OPTIONS") return CYAN method RESET
  return MAGENTA method RESET
}

{
  line = $0

  # Check if line is Firelog / WAF format
  is_firelog = 0
  if (mode == "firelog") {
    is_firelog = 1
  } else if (mode == "auto") {
    if (line ~ /action=/ || line ~ /rule_id=/ || line ~ /[Ww][Aa][Ff]/ || line ~ /[Mm]od[Ss]ecurity/ || line ~ /[Nn]axsi/ || line ~ /BLOCK/ || line ~ /DENY/) {
      is_firelog = 1
    }
  }

  if (is_firelog == 1) {
    # --- FIRELOG / WAF LOG HIGHLIGHTER ---
    # Highlight Actions
    gsub(/action="?BLOCK"?/ , BG_RED " BLOCK " RESET, line)
    gsub(/action="?DENY"?/  , BG_RED " DENY " RESET, line)
    gsub(/action="?DROP"?/  , BG_RED " DROP " RESET, line)
    gsub(/action="?ALLOW"?/ , BG_GRN " ALLOW " RESET, line)
    gsub(/action="?PASS"?/  , BG_GRN " PASS " RESET, line)
    gsub(/action="?LOG"?/   , BG_GRN " LOG " RESET, line)

    # Highlight WAF metadata key-value pairs
    gsub(/rule_id=[0-9]+/, CYAN BOLD "&" RESET, line)
    gsub(/severity=[A-Za-z]+/, RED BOLD "&" RESET, line)
    gsub(/client_ip=([0-9]{1,3}\.){3}[0-9]{1,3}/, MAGENTA BOLD "&" RESET, line)

    # Highlight IP addresses
    gsub(/([0-9]{1,3}\.){3}[0-9]{1,3}/, MAGENTA BOLD "&" RESET, line)

    print CYAN "[FIRELOG] " RESET line

  } else {
    # --- STANDARD NGINX COMBINED LOG HIGHLIGHTER ---
    ip = $1
    user = $3
    time_str = $4 " " $5
    gsub(/^\[/, "", time_str)
    gsub(/\]$/, "", time_str)

    req_start = index(line, "\"")
    if (req_start > 0) {
      rest = substr(line, req_start + 1)
      req_end = index(rest, "\"")
      req_str = substr(rest, 1, req_end - 1)
      post_req = substr(rest, req_end + 1)

      split(req_str, req_parts, " ")
      method = req_parts[1]
      uri = req_parts[2]

      split(post_req, post_parts, " ")
      status = post_parts[1]
      bytes = post_parts[2]

      ref_ua = ""
      ref_start = index(post_req, "\"")
      if (ref_start > 0) {
        ref_ua = substr(post_req, ref_start)
      }

      printf "%s%-15s%s %s[%s]%s %s %s%-35s%s %s %s%-6s%s %s\n",
        MAGENTA BOLD, ip, RESET,
        DIM, time_str, RESET,
        color_method(method),
        WHITE BOLD, uri, RESET,
        color_status(status),
        CYAN, bytes, RESET,
        DIM ref_ua RESET
    } else {
      # Fallback
      gsub(/([0-9]{1,3}\.){3}[0-9]{1,3}/, MAGENTA BOLD "&" RESET, line)
      print line
    }
  }
}
' ${LOG_FILE:+"$LOG_FILE"}
