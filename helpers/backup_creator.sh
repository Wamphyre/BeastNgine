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

log_info "BeastNgine - Backup Creator"
read -p "Please, enter the domain to backup: " WEB

if [ -z "$WEB" ]; then
    log_error "Domain cannot be empty."
fi

WEB_PATH="/usr/local/www/public_html/$WEB"
if [ ! -d "$WEB_PATH" ]; then
    log_error "Directory $WEB_PATH does not exist."
fi

DATE_STR=$(date -I)
BACKUP_DIR="/usr/local/www/backup/$WEB/$DATE_STR"
mkdir -p "$BACKUP_DIR"

log_info "Backing up files..."
tar -czf "$BACKUP_DIR/$WEB-$DATE_STR.tar.gz" -C "/usr/local/www/public_html" "$WEB"

# Intelligent Credential Extraction
if [ -f "$WEB_PATH/wp-config.php" ]; then
    log_info "Detected WordPress configuration. Attempting database backup..."
    
    # Extract DB Name
    DB_NAME=$(grep "DB_NAME" "$WEB_PATH/wp-config.php" | cut -d "'" -f 4)
    # Extract DB User
    DB_USER=$(grep "DB_USER" "$WEB_PATH/wp-config.php" | cut -d "'" -f 4)
    # Extract DB Password
    DB_PASS=$(grep "DB_PASSWORD" "$WEB_PATH/wp-config.php" | cut -d "'" -f 4)

    if [ -n "$DB_NAME" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASS" ]; then
        log_info "Dumping database $DB_NAME..."
        mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/$DB_NAME.sql" \
            || log_info "Database dump failed (possibly invalid credentials). Proceeding with file backup only."
    else
        log_info "Could not extract database credentials. Skipping DB backup."
    fi
else
    log_info "No wp-config.php found. Skipping database backup."
fi

log_info "Backup completed at $BACKUP_DIR"
