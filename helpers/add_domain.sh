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
log_info "BeastNgine - Create New VHOST"

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
    proxy_buffers 4 64k;
    proxy_busy_buffers_size 64k;

    # Upload limit
    client_max_body_size 10m;
    client_body_buffer_size 128k;

    # Cache control
    set \$skip_cache 0;
    if (\$request_method = POST) { set \$skip_cache 1; }
    if (\$query_string != "") { set \$skip_cache 1; }
    if (\$request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") { set \$skip_cache 1; }
    if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") { set \$skip_cache 1; }

    # Static resources
    location ~* \.(xml|ogg|ogv|svg|svgz|eot|otf|woff|woff2|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf|webp|avif|heic)\$ {
        expires max;
        log_not_found off;
        access_log off;
        add_header Cache-Control "public, no-transform";
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Permissions-Policy "interest-cohort=()";
    
    # Logs
    access_log /var/log/nginx/$DOMINIO-access.log;
    error_log /var/log/nginx/$DOMINIO-error.log;
            
    # Bad bots
    if (\$http_user_agent ~* (bot|spider|crawler|slurp|Baiduspider)) { return 403; }

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
	
    # Deny access to sensitive files
    location ~* /(wp-config\.php|xmlrpc\.php|readme\.html|license\.txt) { deny all; }

    # PHP-FPM Status and Ping
    location ~ ^/(status|ping)$ {
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        allow 127.0.0.1;
        deny all;
    }

    location = /favicon.ico { access_log off; log_not_found off; expires max; }
    location = /robots.txt { access_log off; log_not_found off; try_files \$uri \$uri/ /index.php\$is_args\$args; }
    location ~ /\. { access_log off; log_not_found off; deny all; }

    # WordPress Specific
    location ~ ^/wp-content/uploads/.*\.php$ { deny all; }
    location ~* /(?:uploads|files|wp-content|wp-includes|akismet)/.*.php$ { deny all; }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        if (!-f \$document_root\$fastcgi_script_name) { return 404; }
        
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        
        # Timeouts
        fastcgi_read_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_connect_timeout 60s;
        
        # Buffers
        fastcgi_buffer_size 64k;
        fastcgi_buffers 4 64k;
        fastcgi_busy_buffers_size 64k;
        
        # Cache settings
        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 60m;
        fastcgi_hide_header Cache-Control;
        
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ \.php$ { return 404; }
}
EOF

log_info "VHOST for $DOMINIO created successfully."
log_info "Reloading Nginx and PHP-FPM..."
service nginx reload
service php-fpm reload

log_info "Complete!"
