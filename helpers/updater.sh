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

log_info "Updating package repositories and installed packages..."
pkg update && pkg upgrade -y

log_info "Updating base system..."
freebsd-update fetch && freebsd-update install || log_info "FreeBSD Update: No updates needed or interaction required."

log_info "Updating Ports Collection..."
if [ -d "/usr/ports/.git" ]; then
    git -C /usr/ports pull
else
    rm -rf /usr/ports
    git clone --depth 1 https://git.FreeBSD.org/ports.git /usr/ports
fi

log_info "Cleaning up..."
pkg clean -y
pkg autoremove -y

log_info "System update complete!"
