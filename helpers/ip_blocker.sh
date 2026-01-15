#!/bin/sh
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo "${GREEN}[INFO] $1${NC}"; }
log_error() { echo "${RED}[ERROR] $1${NC}"; exit 1; }

# Root check
if [ "$(id -u)" -ne 0 ]; then
   log_error "This script must be run as root"
fi

log_info "Top 20 IPs by connection count (from access.log):"
cd /var/log/nginx || log_error "Nginx log directory not found."

# Default to access.log, but warn if missing
if [ -f "access.log" ]; then
    awk '{print $1 }' access.log | sort | uniq -c | sort -nr | head -20
else
    log_info "No access.log found in /var/log/nginx. Listing all access logs..."
    ls -lh *access.log
fi

echo ""
read -p "Enter IP to block: " IP

if [ -z "$IP" ]; then
    log_error "IP cannot be empty."
fi

# Add to sshguard table which is already blocked in PF config ("table <sshguard> persist")
# This is a cleaner way to block than "route add -blackhole" as it persists via PF state and is managed uniformly.
log_info "Adding $IP to sshguard blacklist table..."
pfctl -t sshguard -T add "$IP" 2>/dev/null || log_error "Failed to add IP to PF table. Is PF running?"

# Also add to the static blacklist file for persistence across reboots if modsecurity is used
BLACKLIST_FILE="/usr/local/etc/modsecurity/ip_blacklist.txt"
if [ -f "$BLACKLIST_FILE" ]; then
    echo "$IP" >> "$BLACKLIST_FILE"
    log_info "Added $IP to ModSecurity blacklist file."
fi

log_info "$IP has been blocked."
