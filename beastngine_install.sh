#!/bin/sh
set -e

# ==========================================
# BeastNgine Server for FreeBSD
# Refactored & Modernized
# ==========================================

# Colors (using tput for reliability)
if command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    NC=$(tput sgr0)
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
fi

# Helper Functions
log_info() {
    printf "${GREEN}[INFO] %s${NC}\n" "$1" >&2
}

log_warn() {
    printf "${YELLOW}[WARN] %s${NC}\n" "$1" >&2
}

log_error() {
    printf "${RED}[ERROR] %s${NC}\n" "$1" >&2
    exit 1
}

# Interactive Version Chooser
choose_version_from_list() {
    name="$1"
    shift
    # Print to stderr to allow capturing stdout
    printf "${YELLOW}Multiple options found for %s. Please select one:${NC}\n" "$name" >&2
    
    i=1
    for pkg in "$@"; do
        printf "%d) %s\n" "$i" "$pkg" >&2
        i=$((i+1))
    done
    
    while true; do
        printf "Enter number (1-%d): " "$((i-1))" >&2
        read choice < /dev/tty
        
        if [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ] 2>/dev/null; then
             count=1
             for pkg in "$@"; do
                 if [ "$count" -eq "$choice" ]; then
                     echo "$pkg"
                     return
                 fi
                 count=$((count+1))
             done
        else
            printf "${RED}Invalid selection. Try again.${NC}\n" >&2
        fi
    done
}

# Robust Detection with Fallback
# Robust Detection with Fallback (Broad Search -> Local Filter)
detect_or_choose() {
    human_name="$1"
    search_query="$2"
    grep_filter="$3"
    mode="${4:-origin}" # default to 'origin' search

    # 1. Broad Search
    if [ "$mode" = "name" ]; then
        # Search by name (-q returns name-version)
        # We need to strip version suffix (e.g. -10.11.6 or -3.11)
        raw_list=$(pkg search -q "$search_query" | sed -E 's/-[0-9][0-9.]*$//' || true)
    else
        # Search by origin (-o -q returns category/name)
        # We strip category
        raw_list=$(pkg search -o -q "$search_query" | cut -d/ -f2 || true)
    fi

    if [ -z "$raw_list" ]; then
        log_warn "No packages found for query: $search_query"
        return 0
    fi

    # 2. Local Filter
    candidates=$(echo "$raw_list" | grep "$grep_filter" | sort -V | uniq)

    if [ -z "$candidates" ]; then
        log_warn "No suitable $human_name version found after filtering."
        return 0
    fi

    # 3. Selection
    count=$(echo "$candidates" | wc -l)
    
    if [ "$count" -eq 1 ]; then
        echo "$candidates"
    else
        highest=$(echo "$candidates" | tail -n1)
        log_info "Auto-selected highest version for $human_name: $highest" >&2
        echo "$highest"
    fi
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
   log_error "This script must be run as root"
fi

# Store script directory for asset file access
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
log_info "Script directory: $SCRIPT_DIR"

# ==========================================
# 0. Preparation & Dynamic Version Detection
# ==========================================
clear
log_info "Starting BeastNgine Installation..."

# Update pkg metadata first to ensure search works
log_info "Updating package repositories..."
pkg update -f

# Ensure git is installed for ports collection
pkg install -y git

log_info "Detecting latest software versions..."
 
# PHP Detection - Interactive Selection
log_info "Available PHP versions: php84, php85"
printf "${YELLOW}Which PHP version would you like to install? (84/85): ${NC}" >&2
read -r PHP_CHOICE < /dev/tty

case "$PHP_CHOICE" in
    84)
        PHP_PKG="php84"
        ;;
    85)
        PHP_PKG="php85"
        ;;
    *)
        log_warn "Invalid choice. Defaulting to php84."
        PHP_PKG="php84"
        ;;
esac

PHP_VER=${PHP_PKG#php}
log_info "Selected PHP Version: $PHP_PKG"

# MariaDB Detection
# Query: "mariadb"
# Filter: match clean name (e.g. mariadb1011-server)
MARIADB_SERVER_PKG=$(detect_or_choose "MariaDB Server" "mariadb" "^mariadb[0-9]\+-server$")
if [ -z "$MARIADB_SERVER_PKG" ]; then
    log_warn "MariaDB selection failed. Defaulting to mariadb1011-server."
    MARIADB_SERVER_PKG="mariadb1011-server"
    MARIADB_CLIENT_PKG="mariadb1011-client"
else
    MARIADB_CLIENT_PKG=$(echo "$MARIADB_SERVER_PKG" | sed 's/-server/-client/')
fi
log_info "Selected MariaDB: $MARIADB_SERVER_PKG"

# Varnish Detection
# Query: "varnish"
# Filter: match clean name (e.g. varnish7)
VARNISH_PKG=$(detect_or_choose "Varnish" "varnish" "^varnish[0-9]\+$")
if [ -z "$VARNISH_PKG" ]; then
    log_warn "Varnish selection failed. Defaulting to varnish7."
    VARNISH_PKG="varnish7"
fi
log_info "Selected Varnish: $VARNISH_PKG"

# Certbot Detection
# Try common Python versions for certbot
log_info "Detecting Certbot..."
for pyver in 311 312 39; do
    # Use rquery to find packages, then strip version suffix
    if pkg rquery -a '%n' | grep -q "^py${pyver}-certbot-nginx$" 2>/dev/null; then
        CERTBOT_PKG="py${pyver}-certbot"
        CERTBOT_NGINX_PKG="py${pyver}-certbot-nginx"
        log_info "Found Certbot: $CERTBOT_PKG"
        break
    fi
done

if [ -z "$CERTBOT_PKG" ]; then
    log_warn "Certbot not found in repositories. Skipping Certbot installation."
    log_warn "You can install it manually later if needed."
    CERTBOT_PKG=""
    CERTBOT_NGINX_PKG=""
fi

# Resource Detection for Tuning
NCPU=$(sysctl -n hw.ncpu)
PHYSMEM_BYTES=$(sysctl -n hw.physmem)
PHYSMEM_MB=$((PHYSMEM_BYTES / 1024 / 1024))
log_info "Hardware Detected: $NCPU CPU Cores, $PHYSMEM_MB MB RAM"

# Tuning Calculations
if [ "$PHYSMEM_MB" -ge 16384 ]; then
    # High Spec (>16GB)
    VFS_MAXVNODES=400000
    SOMAXCONN=4096
    TCP_BUFSPACE=131072
    INNODB_POOL="8G"
    VARNISH_STORAGE_SIZE="2048M"
    NET_MAX_THREADS=$(($NCPU * 2))
    
    # PHP & Nginx High
    NGINX_WORKER_CONNS=4096
    PHP_MAX_CHILDREN=128
    PHP_START_SERVERS=20
    PHP_MIN_SPARE=10
    PHP_MAX_SPARE=30
    PHP_MEMORY_LIMIT="1024M"

elif [ "$PHYSMEM_MB" -ge 8192 ]; then
    # Mid-High (8-16GB)
    VFS_MAXVNODES=200000
    SOMAXCONN=2048
    TCP_BUFSPACE=65536
    INNODB_POOL="4G"
    VARNISH_STORAGE_SIZE="1024M"
    NET_MAX_THREADS=$NCPU
    
    # PHP & Nginx Mid-High
    NGINX_WORKER_CONNS=4096
    PHP_MAX_CHILDREN=64
    PHP_START_SERVERS=15
    PHP_MIN_SPARE=10
    PHP_MAX_SPARE=20
    PHP_MEMORY_LIMIT="512M"

elif [ "$PHYSMEM_MB" -ge 4096 ]; then
    # Mid (4-8GB)
    VFS_MAXVNODES=100000
    SOMAXCONN=1024
    TCP_BUFSPACE=32768
    INNODB_POOL="2G"
    VARNISH_STORAGE_SIZE="512M"
    NET_MAX_THREADS=$NCPU
    
    # PHP & Nginx Mid
    NGINX_WORKER_CONNS=2048
    PHP_MAX_CHILDREN=30
    PHP_START_SERVERS=10
    PHP_MIN_SPARE=5
    PHP_MAX_SPARE=15
    PHP_MEMORY_LIMIT="256M"

else
    # Low (<4GB)
    VFS_MAXVNODES=50000
    SOMAXCONN=512
    TCP_BUFSPACE=16384
    INNODB_POOL="128M" # Safe default
    VARNISH_STORAGE_SIZE="128M"
    NET_MAX_THREADS=2
    
    # PHP & Nginx Low
    NGINX_WORKER_CONNS=1024
    PHP_MAX_CHILDREN=10
    PHP_START_SERVERS=2
    PHP_MIN_SPARE=1
    PHP_MAX_SPARE=3
    PHP_MEMORY_LIMIT="256M"
fi

# ==========================================
# 1. System Update & Ports
# ==========================================
log_info "Upgrading installed packages..."
pkg upgrade -y

log_info "Extracting/Updating Ports Collection..."
log_info "Extracting/Updating Ports Collection..."
if [ -d "/usr/ports/.git" ]; then
    log_info "/usr/ports is already a git repo. Pulling changes..."
    git -C /usr/ports pull
elif [ -d "/usr/ports" ]; then
    log_warn "/usr/ports exists but is NOT a git repo. Backing up and cloning fresh..."
    mv /usr/ports "/usr/ports.bak_$(date +%Y%m%d_%H%M%S)"
    git clone --depth 1 https://git.FreeBSD.org/ports.git /usr/ports
else
    log_info "Cloning Ports Collection..."
    git clone --depth 1 https://git.FreeBSD.org/ports.git /usr/ports
fi

# ==========================================
# 2. Package Installation
# ==========================================
log_info "Installing Dependencies..."

# Construct and Verify PHP extensions list dynamically
DESIRED_EXTS="bcmath ctype curl dom exif fileinfo filter ftp gd iconv intl mbstring mysqli opcache pdo pecl-redis session tokenizer xml zip zlib"
VALID_PHP_EXTS=""

log_info "Verifying PHP extensions..."
for ext in $DESIRED_EXTS; do
    PKG_NAME="${PHP_PKG}-${ext}"
    # Check if package exists in repository using rquery (more reliable than search)
    if pkg rquery -U '%n' | grep -q "^${PKG_NAME}$" 2>/dev/null; then
        VALID_PHP_EXTS="$VALID_PHP_EXTS $PKG_NAME"
    else
        log_warn "PHP extension '$PKG_NAME' not found in repositories. Skipping."
    fi
done

pkg install -y $PHP_PKG $VALID_PHP_EXTS
pkg install -y $MARIADB_SERVER_PKG $MARIADB_CLIENT_PKG

# Certbot - only install if available
if [ -n "$CERTBOT_PKG" ]; then
    pkg install -y $CERTBOT_PKG $CERTBOT_NGINX_PKG
else
    log_warn "Skipping Certbot installation (not available in repositories)"
fi

pkg install -y $VARNISH_PKG valkey
pkg install -y nano htop libtool automake autoconf curl
pkg install -y libxml2 libxslt modsecurity3 python binutils pcre libgd

# SSHGuard - check if already installed
if pkg info -e sshguard 2>/dev/null; then
    log_warn "SSHGuard is already installed. Skipping compilation."
else
    log_info "Installing SSHGuard from ports..."
    cd /usr/ports/security/sshguard && make install clean BATCH=yes
fi

# Configure SSHGuard
if [ -f "${SCRIPT_DIR}/assets/sshguard.conf" ]; then
    log_info "Configuring SSHGuard..."
    mv /usr/local/etc/sshguard.conf /usr/local/etc/sshguard.conf.bk 2>/dev/null || true
    cp "${SCRIPT_DIR}/assets/sshguard.conf" /usr/local/etc/sshguard.conf
else
    log_warn "${SCRIPT_DIR}/assets/sshguard.conf not found. Skipping copy."
fi

# ==========================================
# 3. Nginx Compilation (Custom)
# ==========================================
# Check if Nginx is already installed
if pkg info -e nginx 2>/dev/null; then
    log_warn "Nginx is already installed. Skipping compilation."
    log_warn "To recompile, run: pkg delete nginx && rerun this script"
else
    log_info "Compiling Nginx with ModSecurity3 and Brotli..."

# Set Nginx build options using FreeBSD ports syntax
cd /usr/ports/www/nginx

# Build with specific options enabled
make \
    OPTIONS_SET="BROTLI MODSECURITY3 HTTP HTTPV2 HTTPV3 HTTP_SSL HTTP_REALIP HTTP_ADDITION HTTP_SUB HTTP_DAV HTTP_FLV HTTP_MP4 HTTP_GUNZIP_FILTER HTTP_GZIP_STATIC HTTP_AUTH_REQ HTTP_RANDOM_INDEX HTTP_SECURE_LINK HTTP_SLICE HTTP_STATUS MAIL MAIL_SSL STREAM STREAM_SSL STREAM_REALIP STREAM_SSL_PREREAD HTTP_GZIP HTTP_REDIS HTTP_IMAGE_FILTER HTTP_XSLT THREADS CACHE_PURGE" \
    OPTIONS_UNSET="DEBUG DEBUGLOG MAIL_IMAP MAIL_POP3 MAIL_SMTP" \
    install clean BATCH=yes

# Verify ModSecurity module was compiled
if [ ! -f "/usr/local/libexec/nginx/ngx_http_modsecurity_module.so" ]; then
    log_warn "ModSecurity module not found. Disabling it in nginx.conf"
    sed -i '' 's/^load_module.*modsecurity_module.so;/# &/' "${SCRIPT_DIR}/assets/nginx.conf"
    sed -i '' 's/^[[:space:]]*modsecurity /# &/' "${SCRIPT_DIR}/assets/nginx.conf"
    sed -i '' 's/^[[:space:]]*modsecurity_rules_file /# &/' "${SCRIPT_DIR}/assets/nginx.conf"
fi

# Verify Brotli modules
if [ ! -f "/usr/local/libexec/nginx/ngx_http_brotli_filter_module.so" ]; then
    log_warn "Brotli modules not found. Disabling in nginx.conf"
    sed -i '' 's/^load_module.*brotli.*module.so;/# &/' "${SCRIPT_DIR}/assets/nginx.conf"
    sed -i '' 's/^[[:space:]]*brotli /# &/' "${SCRIPT_DIR}/assets/nginx.conf"
fi
fi

# ==========================================
# 4. ModSecurity OWASP CRS Setup
# ==========================================
log_info "Setting up ModSecurity OWASP CRS..."
mkdir -p /usr/local/etc/modsecurity

# Download OWASP CRS if not exists
if [ ! -d "/tmp/owasp-modsecurity-crs" ]; then
    log_info "Downloading OWASP ModSecurity CRS..."
    cd /tmp
    git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
fi

# Copy configuration files
log_info "Installing ModSecurity rules..."
cd /tmp/owasp-modsecurity-crs
cp crs-setup.conf.example /usr/local/etc/modsecurity/crs-setup.conf 2>/dev/null || log_warn "crs-setup.conf.example not found"

# Create rules directory and copy rules
mkdir -p /usr/local/etc/modsecurity/crs
if [ -d "rules" ]; then
    cp -f rules/* /usr/local/etc/modsecurity/crs/ 2>/dev/null || log_warn "Failed to copy some rules"
else
    log_warn "Rules directory not found in OWASP CRS"
fi

# Enable Includes in modsecurity.conf if it exists
if [ -f "/usr/local/etc/modsecurity/modsecurity.conf" ]; then
    if ! grep -q "Include.*crs.*conf" /usr/local/etc/modsecurity/modsecurity.conf; then
        echo 'Include "/usr/local/etc/modsecurity/crs/*.conf"' >> /usr/local/etc/modsecurity/modsecurity.conf
    fi
    # Enable Rule Engine
    sed -i '' 's/^[[:space:]]*SecRuleEngine DetectionOnly/SecRuleEngine On/' /usr/local/etc/modsecurity/modsecurity.conf
else
    log_warn "modsecurity.conf not found, skipping ModSecurity configuration"
fi

# Disable specific rule being problematic
mv /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf_OFF 2>/dev/null || true

# Copy local security configs
cp "${SCRIPT_DIR}/assets/ip_blacklist.txt" /usr/local/etc/modsecurity/ 2>/dev/null || log_warn "ip_blacklist.txt not found"
cp "${SCRIPT_DIR}/assets/ip_blacklist.conf" /usr/local/etc/modsecurity/ 2>/dev/null || log_warn "ip_blacklist.conf not found"
cp "${SCRIPT_DIR}/assets/unicode.mapping" /usr/local/etc/modsecurity/ 2>/dev/null || log_warn "unicode.mapping not found"

# ==========================================
# 5. Service Configuration (Sysrc)
# ==========================================
log_info "Enabling and Configuring Services..."

# Base Services
sysrc nginx_enable="YES"
sysrc php_fpm_enable="YES"
sysrc valkey_enable="YES"

# Varnish
sysrc varnishd_enable="YES"
sysrc varnishd_listen=":80"
sysrc varnishd_backend="localhost:8080"
sysrc varnishd_storage="malloc,${VARNISH_STORAGE_SIZE}"
sysrc varnishd_admin=":8081"

# Firewall & Security
sysrc pf_enable="YES"
sysrc pf_rules="/etc/pf.conf" 
sysrc pflog_enable="YES"
sysrc pflog_logfile="/var/log/pflog"
sysrc sshguard_enable="YES"

# System Tuning & Cleaning
sysrc clear_tmp_enable="YES"
sysrc syslogd_flags="-ss"
sysrc microcode_update_enable="YES"

# Sendmail Disabling
sysrc sendmail_submit_enable="NO"
sysrc sendmail_msp_queue_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_enable="NO"
sysrc dumpdev="NO"

# MySQL
sysrc mysql_enable="YES"
sysrc mysql_args="--bind-address=127.0.0.1"

# ==========================================
# 6. Config File Deployment (Local Copy)
# ==========================================
log_info "Deploying Configuration Files..."

# PHP-FPM
mkdir -p /var/log/php-fpm
mv /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf.bk 2>/dev/null || true
cp "${SCRIPT_DIR}/assets/www.conf" /usr/local/etc/php-fpm.d/
# Apply Dynamic PHP Tuning using sed
sed -i '' "s/^pm.max_children.*/pm.max_children = ${PHP_MAX_CHILDREN}/" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s/^pm.start_servers.*/pm.start_servers = ${PHP_START_SERVERS}/" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s/^pm.min_spare_servers.*/pm.min_spare_servers = ${PHP_MIN_SPARE}/" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s/^pm.max_spare_servers.*/pm.max_spare_servers = ${PHP_MAX_SPARE}/" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s/^php_value\[memory_limit\].*/php_value[memory_limit] = ${PHP_MEMORY_LIMIT}/" /usr/local/etc/php-fpm.d/www.conf

# Varnish
mkdir -p /usr/local/etc/varnish
cp "${SCRIPT_DIR}/assets/wordpress.vcl" /usr/local/etc/varnish/

# Valkey
cp "${SCRIPT_DIR}/assets/valkey.conf" /usr/local/etc/

# PHP
mv /usr/local/etc/php.ini-production /usr/local/etc/php.ini-production.bk 2>/dev/null || true
cp "${SCRIPT_DIR}/assets/php.ini" /usr/local/etc/

# Nginx
mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.bk 2>/dev/null || true
cp "${SCRIPT_DIR}/assets/nginx.conf" /usr/local/etc/nginx/
# Apply Dynamic Nginx Tuning
sed -i '' "s/worker_connections [0-9]*;/worker_connections ${NGINX_WORKER_CONNS};/" /usr/local/etc/nginx/nginx.conf

mv /usr/local/etc/nginx/mime.types /usr/local/etc/nginx/mime.types.bk 2>/dev/null || true
cp "${SCRIPT_DIR}/assets/mime.types" /usr/local/etc/nginx/

mkdir -p /usr/local/etc/nginx/conf.d

# Default Vhost
DOMINIO=$(hostname)
log_info "Creating default vhost for hostname: $DOMINIO"
cat <<EOF > /usr/local/etc/nginx/conf.d/default_vhost.conf
server {
    listen 8080 default_server;
    listen [::]:8080 default_server;
    server_name $DOMINIO www.$DOMINIO;
    root /usr/local/www/public_html;
    index index.php index.html;

    resolver 1.1.1.1;
    error_page 405 =200 \$uri;
    access_log /var/log/nginx/${DOMINIO}-access.log;
    error_log /var/log/nginx/${DOMINIO}-error.log;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    
    location ~* /xmlrpc\.php { deny all; }

    location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)\$ {
        expires 1M; access_log off; add_header Cache-Control "public";
    }

    location ~* \.(?:css|js)\$ {
        expires 1y; access_log off; add_header Cache-Control "public";
    }

    location = ^/favicon.ico { access_log off; log_not_found off; }
    location = ^/robots.txt { log_not_found off; access_log off; allow all; }
    location ~ /\. { access_log off; log_not_found off; deny all; }

    location ~ [^/]\.php(/|$) {
        root /usr/local/www/public_html;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$request_filename;    
        include fastcgi_params;
    }
}
EOF

# Directories & Permissions
mkdir -p /usr/local/www/public_html
chown -R www:www /usr/local/www/public_html

# ==========================================
# 7. Start Services & DB Init
# ==========================================
log_info "Starting Services..."

# Test Nginx configuration first
log_info "Testing Nginx configuration..."
if ! /usr/local/sbin/nginx -t 2>&1 | grep -q "successful"; then
    log_warn "Nginx configuration test failed. Attempting clean rebuild without ModSecurity..."
    
    # Stop any running nginx processes
    pkill nginx 2>/dev/null || true
    
    # Clean up nginx and modsecurity
    log_info "Removing nginx and modsecurity3..."
    pkg delete -y nginx modsecurity3 2>/dev/null || true
    
    # Clean ports
    cd /usr/ports/www/nginx && make clean 2>/dev/null || true
    
    # Rebuild nginx WITHOUT ModSecurity
    log_info "Recompiling Nginx without ModSecurity..."
    
    cd /usr/ports/www/nginx
    make \
        OPTIONS_SET="BROTLI HTTP HTTPV2 HTTPV3 HTTP_SSL HTTP_REALIP STREAM STREAM_SSL THREADS" \
        OPTIONS_UNSET="MODSECURITY3 DEBUG" \
        install clean BATCH=yes
    
    # Disable ModSecurity in config
    log_info "Disabling ModSecurity in nginx.conf..."
    sed -i '' 's/^load_module.*modsecurity_module.so;/# &/' /usr/local/etc/nginx/nginx.conf
    sed -i '' 's/^[[:space:]]*modsecurity /# &/' /usr/local/etc/nginx/nginx.conf
    sed -i '' 's/^[[:space:]]*modsecurity_rules_file /# &/' /usr/local/etc/nginx/nginx.conf
    
    # Test again
    if ! /usr/local/sbin/nginx -t 2>&1 | grep -q "successful"; then
        log_error "Nginx configuration still invalid. Check: /usr/local/sbin/nginx -t"
    fi
fi

# Try to start Nginx
service nginx start
sleep 3

# Verify nginx is actually running by checking for process
if ! pgrep -q nginx; then
    log_error "Nginx failed to start. Check logs: tail -f /var/log/nginx/error.log"
else
    log_info "Nginx started successfully"
fi

service varnishd start
service valkey start
service microcode_update start
service mysql-server start || service mysql-server onestart

sleep 5
log_info "Securing MariaDB/MySQL..."
/usr/local/bin/mysql_secure_installation

# ==========================================
# 8. System Hardening (Sysctl & Loader)
# ==========================================
log_info "Applying System Hardening & Tuning..."

# Sysctl
cat <<EOF >> /etc/sysctl.conf
# File System Performance
vfs.read_max=128
vfs.cache.maxvnodes=${VFS_MAXVNODES}
kern.sched.steal_cores=1
vm.pmap.sp_enabled=1
kern.ipc.somaxconn=${SOMAXCONN}
net.inet.tcp.mssdflt=1460
net.inet.tcp.minmss=536
net.inet.tcp.cc.algorithm=cubic
net.inet.tcp.blackhole=2
net.inet.udp.blackhole=1
# Dynamic TCP Buffers
net.inet.tcp.sendspace=${TCP_BUFSPACE}
net.inet.tcp.recvspace=${TCP_BUFSPACE}
kern.coredump=0
kern.sched.preempt_thresh=224
vfs.usermount=1
vfs.vmiodirenable=0
EOF

# Loader configuration
cat <<EOF >> /boot/loader.conf
hw.usb.template=3
umodem_load="YES"
boot_multicons="YES"
boot_serial="YES"
beastie_disable="YES"
loader_color="NO"
EOF

# Database Optimization (my.cnf)
# Check for mysql directory
mkdir -p /usr/local/etc/mysql
cat <<EOF >> /usr/local/etc/mysql/my.cnf
[mysqld]
key_buffer_size = 8M
max_allowed_packet = 16M
thread_stack = 192K
thread_cache_size = 8
query_cache_limit = 512K
query_cache_size = 8M
default-storage-engine = innodb
innodb_buffer_pool_size = ${INNODB_POOL}
innodb_log_file_size = 32M
innodb_flush_log_at_trx_commit = 1
innodb_file_per_table = 1
max_connections = 50
EOF

# ==========================================
# 9. Firewall Setup (PF)
# ==========================================
log_info "Configuring Firewall (PF)..."
echo
ifconfig | grep :
echo
read -p "Please, enter the network interface name (e.g., vtnet0, em0): " INTERFAZ

if [ -n "$INTERFAZ" ]; then
    cat <<EOF > /etc/pf.conf
ext_if="$INTERFAZ"
ssh_port = "22"
inbound_tcp_services = "{80, 443, 21, 25, \$ssh_port }"
inbound_udp_services = "{80, 8080, 443}"

set block-policy return
set loginterface \$ext_if
set skip on lo
scrub in on \$ext_if all fragment reassemble
antispoof for \$ext_if

block all
pass quick on \$ext_if proto icmp
pass quick on \$ext_if proto icmp6
pass in quick on \$ext_if proto tcp to port \$inbound_tcp_services
pass in quick on \$ext_if proto udp to port \$inbound_udp_services
pass out quick on \$ext_if

table <sshguard> persist
block in quick on \$ext_if from <sshguard>
EOF

    # Dynamic IP rule (using curl) is a bit fragile if network is down, but keeping original logic
    MY_IP=\$(curl -s ifconfig.me || echo "0.0.0.0")
    cat <<EOF >> /etc/pf.conf
pass in on \$ext_if proto tcp from any to $MY_IP port 21 flags S/SA synproxy state
pass in on \$ext_if proto tcp from any to $MY_IP port > 49151 keep state
pass out keep state
EOF

    kldload pf || true
    service pf start || log_warn "Failed to start PF immediately"
    service sshguard start
    log_info "Firewall configured on $INTERFAZ"
else
    log_warn "No interface selected. PF configuration skipped."
fi

# ==========================================
# 10. Final Cleanup
# ==========================================
log_info "Cleaning up..."
pkg clean -y
pkg autoremove -y

log_info "Installation Complete!"
log_info "Please restart your server to apply all kernel/loader changes."
