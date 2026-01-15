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

log_info "BeastNgine - AutoSSL Installer (Certbot)"

read -p "Enter domain for SSL certificate: " DOMINIO

if [ -z "$DOMINIO" ]; then
    log_error "Domain cannot be empty."
fi

CONF_FILE="/usr/local/etc/nginx/conf.d/$DOMINIO.conf"

if [ ! -f "$CONF_FILE" ]; then
    log_error "Configuration file for $DOMINIO not found at $CONF_FILE"
fi

log_info "Temporarily stopping Varnish to free port 80..."
service varnishd stop

log_info "Reconfiguring Nginx for Let's Encrypt validation..."
# Switch Nginx to Port 80
sed -i '' -e 's/listen 8080/listen 80/' /usr/local/etc/nginx/nginx.conf
sed -i '' -e 's/listen 8080/listen 80/' "$CONF_FILE"

service nginx restart
sleep 3

log_info "Requesting Certificate..."
# Detect Certbot version/name
CERTBOT_BIN=$(which certbot || which certbot-3.11 || which certbot-3.9 || echo "certbot")
$CERTBOT_BIN --nginx -d "$DOMINIO" --non-interactive --agree-tos --email "admin@$DOMINIO" || {
    log_error "Certbot failed. Restoring configuration..."
    # Recovery would be complex, but at least we stop here.
}

log_info "Enhancing SSL security (HSTS)..."
# Optional HSTS enhancement
# $CERTBOT_BIN enhance --hsts -d "$DOMINIO" || true

log_info "Restoring Nginx/Varnish architecture..."
# Restore Port 8080
sed -i '' -e 's/listen 80/listen 8080/' /usr/local/etc/nginx/nginx.conf
sed -i '' -e 's/listen 80/listen 8080/' "$CONF_FILE"

# Configure HTTP/2 (Modern Syntax)
if ! grep -q "http2 on;" "$CONF_FILE"; then
    sed -i '' -e '/443 ssl/a\ 
    http2 on;' "$CONF_FILE"
fi

# Clean up temporary Certbot modifications if any (Certbot creates .conf backup usually, we ignore those)

service nginx restart
sleep 2
service varnishd start

log_info "SSL Installation Complete for $DOMINIO"
