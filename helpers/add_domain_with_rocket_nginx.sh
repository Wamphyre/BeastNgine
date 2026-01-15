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

clear
log_info "BeastNgine - Create New VHOST (WP Rocket Optimized)"

read -p "Please, enter the domain name (e.g., example.com): " DOMINIO

if [ -z "$DOMINIO" ]; then
    log_error "Domain name cannot be empty."
fi

CONF_PATH="/usr/local/etc/nginx/conf.d/$DOMINIO.conf"
WEB_ROOT="/usr/local/www/public_html/$DOMINIO"

if [ -f "$CONF_PATH" ]; then
    log_error "Configuration for $DOMINIO already exists at $CONF_PATH"
fi

log_info "Creating directory structure..."
mkdir -p "$WEB_ROOT"
chown -R www:www "$WEB_ROOT"

log_info "Creating Nginx configuration..."
cat << EOF > "$CONF_PATH"
server {
    listen 8080;
    listen [::]:8080;

    server_name $DOMINIO www.$DOMINIO;

    root $WEB_ROOT;
    index index.php index.html;

    # Brotli settings
    brotli on;
    brotli_comp_level 4;   
    brotli_types text/plain text/css application/json application/javascript application/xml application/x-font-ttf application/vnd.ms-fontobject image/svg+xml image/x-icon image/webp;

    # Proxy buffers
    proxy_buffer_size 64k;
    proxy_buffers 8 64k;
    proxy_busy_buffers_size 128k;

    # Upload limit
    client_max_body_size 100m;
    client_body_buffer_size 128k;

    # WP Rocket Cache Control
    set \$cache_uri \$request_uri;

    # Bypass cache for query strings
    if (\$query_string != "") { set \$cache_uri 'null cache'; }

    # Don't cache URIs containing the following segments
    if (\$request_uri ~* "(/wp-admin/|/xmlrpc.php|/wp-(app|cron|login|register|mail).php|wp-.*.php|/feed/|index.php|wp-comments-popup.php|wp-links-opml.php|wp-locations.php|sitemap(_index)?.xml|[a-z0-9_-]+-sitemap([0-9]+)?.xml|(.*)preview(.*)|\?(.+)|/checkout/|/cart/|/my-account/|/wc-api/|/wp-json/|/webp-express/|addons|removed_item|undo_item|applied_coupon|removed_coupon|update_shipping_method|update_order_review)") {
        set \$cache_uri 'null cache';
    }

    # Don't use the cache for logged-in users or recent commenters
    if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_logged_in|woocommerce_items_in_cart|woocommerce_cart_hash|wptouch_switch_toggle|comment_author_email_") {
        set \$cache_uri 'null cache';
    }

    # Use cached or actual file if they exists, otherwise pass request to WordPress
    location / {
        try_files /wp-content/cache/wp-rocket/$DOMINIO\$cache_uri/_index.html \$uri \$uri/ /index.php\$is_args\$args;
        error_page 404 = @nocache;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Permissions-Policy "interest-cohort=()";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    }

    location @nocache {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    # Cache static files
    location ~* \.(ogg|ogv|svg|svgz|eot|otf|woff|woff2|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf|webp|avif|heic)\$ {
        expires max;
        log_not_found off;
        access_log off;
        add_header Cache-Control "public, no-transform";
        add_header Vary "Accept-Encoding";
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    
    # Logs
    access_log /var/log/nginx/$DOMINIO-access.log;
    error_log /var/log/nginx/$DOMINIO-error.log;
            
    # Bad bots
    if (\$http_user_agent ~* (bot|crawler|spider|slurp|Baiduspider|80legs|360Spider|Sosospider|Sogou)) { return 403; }

    # WordPress Security
    location ~* /(?:uploads|files|wp-content|wp-includes|akismet|wp-content/cache|wp-content/themes)/*.*.php\$ { deny all; access_log off; log_not_found off; }
    location ~* /(wp-config\.php|xmlrpc\.php|readme\.html|license\.txt|wp-cli\.yml|wp-config-sample\.php) { deny all; access_log off; log_not_found off; }

    location = /favicon.ico { access_log off; log_not_found off; expires max; }
    location = /robots.txt { try_files \$uri \$uri/ /index.php\$is_args\$args; access_log off; log_not_found off; }
    location ~ /\. { access_log off; log_not_found off; deny all; }

    # PHP handling
    location ~ [^/]\.php(/|\$) {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
        fastcgi_split_path_info ^(.+?\.php)(/.*)\$;
        
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_read_timeout 600s;
        fastcgi_send_timeout 600s;
        fastcgi_connect_timeout 60s;
        
        # Cache settings
        fastcgi_cache_bypass \$cache_uri;
        fastcgi_no_cache \$cache_uri;
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 60m;
        fastcgi_cache_use_stale error timeout http_500 http_503;
        fastcgi_cache_lock on;
        
        fastcgi_hide_header Cache-Control;
        fastcgi_hide_header X-Powered-By;
        
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ \.php\$ { return 404; }

    # WP Rocket specific rules
    location ~ /wp-content/cache/wp-rocket/.*html\$ {
        add_header Vary "Accept-Encoding, Cookie";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header X-Rocket-Cache "Hit";
        expires 30s;
    }

    location ~ /wp-content/cache/wp-rocket/.*_gzip\$ {
        gzip off;
        types {}
        default_type text/html;
        add_header Content-Encoding gzip;
        add_header Vary "Accept-Encoding, Cookie";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header X-Rocket-Cache "Hit";
        expires 30s;
    }

    location ~ /wp-content/cache/wp-rocket/.*-mobile\.html\$ {
        add_header Vary "Accept-Encoding, Cookie, User-Agent";
    }
}
EOF

log_info "VHOST for $DOMINIO created with WP Rocket optimizations."
log_info "Reloading Nginx and PHP-FPM..."
service nginx reload
service php-fpm reload

log_info "Complete!"
