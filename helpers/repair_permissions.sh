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

WEB_ROOT="/usr/local/www/public_html"

if [ ! -d "$WEB_ROOT" ]; then
    log_error "Web root directory $WEB_ROOT does not exist."
fi

log_info "Repairing ownership on $WEB_ROOT..."
chown -R www:www "$WEB_ROOT"

log_info "Repairing file permissions (664) and directory permissions (775)..."
cd "$WEB_ROOT"
find . -type f -exec chmod 664 {} +
find . -type d -exec chmod 775 {} +

log_info "Permissions repaired successfully!"
