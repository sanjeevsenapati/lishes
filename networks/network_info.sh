#!/bin/bash

echo "Network Devices and IP Addresses:"
echo "----------------------------------"

os_type=$(uname)

if [[ "$os_type" == "Darwin" ]]; then
  # macOS command
  networksetup -listallhardwareports | awk '/Hardware Port|Device/ {print $0}' | while read -r line; do
    if [[ $line == *"Hardware Port"* ]]; then
      echo "$line"
    else
      iface=$(echo "$line" | awk '{print $2}')
      ip_address=$(ifconfig "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}')
      if [ -n "$ip_address" ]; then
        echo "Interface: $iface"
        echo "IP Address: $ip_address"
        echo "----------------------------------"
      fi
    fi
  done
elif [[ "$os_type" == "Linux" ]]; then
  # Linux command
  for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
    ip_address=$(ip -o -4 addr show "$iface" 2>/dev/null | awk '{print $4}')
    if [ -n "$ip_address" ]; then
      echo "Interface: $iface"
      echo "IP Address: $ip_address"
      echo "----------------------------------"
    fi
  done
else
  echo "Unsupported OS: $os_type"
  exit 1
fi
