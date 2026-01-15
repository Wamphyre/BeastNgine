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

log_info "Autowordpress - BeastNgine"

# Check if wp-cli is available, arguably better but stick to basic zip method for compatibility with base install
log_info "Downloading latest WordPress..."
if [ -f "latest.zip" ]; then rm "latest.zip"; fi
fetch -q http://wordpress.org/latest.zip || wget -q http://wordpress.org/latest.zip

log_info "Extracting..."
unzip -q -o latest.zip
rm latest.zip

log_info "Moving files to current directory..."
if [ -d "wordpress" ]; then
    cp -Rf wordpress/* .
    rm -rf wordpress
else
    log_error "Extraction failed or wordpress folder not found."
fi

log_info "Applying permissions..."
chown -R www:www .
find . -type f -exec chmod 664 {} +
find . -type d -exec chmod 775 {} +

log_info "WordPress downloaded and extracted successfully!"
