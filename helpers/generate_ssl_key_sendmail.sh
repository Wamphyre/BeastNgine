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

log_info "Generating Diffie-Hellman parameters (4096 bits)..."
log_info "This may take a long time."

if [ -d "/etc/mail/certs" ]; then
    cd /etc/mail/certs && openssl dhparam -out dh.param 4096
    log_info "Done."
else
    log_error "Directory /etc/mail/certs does not exist."
fi
