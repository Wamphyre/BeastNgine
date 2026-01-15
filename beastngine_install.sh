#!/bin/sh
set -e

# ==========================================
# BeastNgine Server for FreeBSD
# Refactored & Modernized
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Helper Functions
log_info() {
    printf "${GREEN}[INFO] %s${NC}\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN] %s${NC}\n" "$1"
}

log_error() {
    printf "${RED}[ERROR] %s${NC}\n" "$1"
    exit 1
}

get_latest_version() {
    pattern="$1"
    # Search for regex, strip version, sort version number numerically, take last
    pkg search -x "$pattern" | cut -d ' ' -f 1 | grep -v 'php[0-9]*-' | sort -V | tail -n1
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
   log_error "This script must be run as root"
fi

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

# PHP Detection (looks for highest php[0-9][0-9])
PHP_PKG=$(get_latest_version '^php[0-9]{2}$')
if [ -z "$PHP_PKG" ]; then
    log_warn "Could not auto-detect PHP version. Defaulting to php83."
    PHP_PKG="php83"
fi
PHP_VER=${PHP_PKG#php} # extracts '83' from 'php83'
log_info "Selected PHP Version: $PHP_PKG"

# MariaDB Detection (looks for mariadb[0-9]*-server)
MARIADB_SERVER_PKG=$(get_latest_version '^mariadb[0-9]+-server$')
if [ -z "$MARIADB_SERVER_PKG" ]; then
    log_warn "Could not auto-detect MariaDB version. Defaulting to mariadb1011-server."
    MARIADB_SERVER_PKG="mariadb1011-server"
    MARIADB_CLIENT_PKG="mariadb1011-client"
else
    # derive client name (e.g., mariadb114-server -> mariadb114-client)
    MARIADB_CLIENT_PKG=$(echo "$MARIADB_SERVER_PKG" | sed 's/-server/-client/')
fi
log_info "Selected MariaDB: $MARIADB_SERVER_PKG"

# Varnish Detection
VARNISH_PKG=$(get_latest_version '^varnish[0-9]+$')
if [ -z "$VARNISH_PKG" ]; then
    log_warn "Could not auto-detect Varnish version. Defaulting to varnish7."
    VARNISH_PKG="varnish7"
fi
log_info "Selected Varnish: $VARNISH_PKG"

# Certbot Detection
CERTBOT_PKG=$(get_latest_version '^py[0-9]+-certbot$')
CERTBOT_NGINX_PKG=$(get_latest_version '^py[0-9]+-certbot-nginx$')
if [ -z "$CERTBOT_PKG" ]; then
    CERTBOT_PKG="py39-certbot"
    CERTBOT_NGINX_PKG="py39-certbot-nginx"
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

# Construct PHP extensions list dynamically
PHP_EXTS="${PHP_PKG}-bcmath ${PHP_PKG}-ctype ${PHP_PKG}-curl ${PHP_PKG}-dom \
${PHP_PKG}-exif ${PHP_PKG}-fileinfo ${PHP_PKG}-filter ${PHP_PKG}-ftp \
${PHP_PKG}-gd ${PHP_PKG}-iconv ${PHP_PKG}-intl ${PHP_PKG}-mbstring \
${PHP_PKG}-mysqli ${PHP_PKG}-opcache ${PHP_PKG}-pdo ${PHP_PKG}-pecl-redis \
${PHP_PKG}-session ${PHP_PKG}-tokenizer ${PHP_PKG}-xml ${PHP_PKG}-zip ${PHP_PKG}-zlib"

pkg install -y $PHP_PKG $PHP_EXTS
pkg install -y $MARIADB_SERVER_PKG $MARIADB_CLIENT_PKG
pkg install -y $CERTBOT_PKG $CERTBOT_NGINX_PKG
pkg install -y $VARNISH_PKG valkey
pkg install -y nano htop libtool automake autoconf curl
pkg install -y libxml2 libxslt modsecurity3 python binutils pcre libgd devcpu-data

# SSHGuard
cd /usr/ports/security/sshguard && make install clean BATCH=yes

# Configure SSHGuard
if [ -f "assets/sshguard.conf" ]; then
    log_info "Configuring SSHGuard..."
    mv /usr/local/etc/sshguard.conf /usr/local/etc/sshguard.conf.bk 2>/dev/null || true
    cp assets/sshguard.conf /usr/local/etc/sshguard.conf
else
    log_warn "assets/sshguard.conf not found. Skipping copy."
fi

# ==========================================
# 3. Nginx Compilation (Custom)
# ==========================================
log_info "Compiling Nginx with ModSecurity3 and Brotli..."

# Compilation flags
NGINX_OPTIONS="-D AJP=off -D ARRAYVAR=off -D AWS_AUTH=off -D BROTLI=on -D CACHE_PURGE=on \
-D CT=off -D DEBUG=off -D DEBUGLOG=off -D DEVEL_KIT=off -D DRIZZLE=off -D DSO=on \
-D DYNAMIC_UPSTREAM=off -D ECHO=off -D ENCRYPTSESSION=off -D FILE_AIO=on -D FIPS_CHECK=off \
-D FORMINPUT=off -D GOOGLE_PERFTOOLS=off -D GRIDFS=off -D GSSAPI_HEIMDAL=off -D GSSAPI_MIT=off \
-D HEADERS_MORE=off -D HTTP=on -D HTTPV2=on -D HTTPV3=on -D HTTPV3_BORING=off \
-D HTTPV3_LSSL=off -D HTTPV3_QTLS=off -D HTTP_ACCEPT_LANGUAGE=off -D HTTP_ADDITION=on \
-D HTTP_AUTH_DIGEST=off -D HTTP_AUTH_KRB5=off -D HTTP_AUTH_LDAP=off -D HTTP_AUTH_PAM=off \
-D HTTP_AUTH_REQ=on -D HTTP_CACHE=on -D HTTP_DAV=on -D HTTP_DAV_EXT=off \
-D HTTP_DEGRADATION=off -D HTTP_EVAL=off -D HTTP_FANCYINDEX=off -D HTTP_FLV=on \
-D HTTP_FOOTER=off -D HTTP_GEOIP2=on -D HTTP_GUNZIP_FILTER=on -D HTTP_GZIP_STATIC=on \
-D HTTP_IMAGE_FILTER=on -D HTTP_IP2LOCATION=on -D HTTP_IP2PROXY=on -D HTTP_JSON_STATUS=off \
-D HTTP_MOGILEFS=off -D HTTP_MP4=on -D HTTP_NOTICE=off -D HTTP_PERL=off \
-D HTTP_PUSH=off -D HTTP_PUSH_STREAM=off -D HTTP_RANDOM_INDEX=on -D HTTP_REALIP=on \
-D HTTP_REDIS=on -D HTTP_SECURE_LINK=on -D HTTP_SLICE=on -D HTTP_SLICE_AHEAD=off \
-D HTTP_SSL=on -D HTTP_STATUS=on -D HTTP_SUB=on -D HTTP_SUBS_FILTER=off \
-D HTTP_TARANTOOL=off -D HTTP_UPLOAD=off -D HTTP_UPLOAD_PROGRESS=off -D HTTP_UPSTREAM_CHECK=off \
-D HTTP_UPSTREAM_FAIR=off -D HTTP_UPSTREAM_STICKY=off -D HTTP_VIDEO_THUMBEXTRACTOR=off \
-D HTTP_XSLT=on -D HTTP_ZIP=off -D ICONV=off -D IPV6=on -D LET=off -D LINK=off \
-D LUA=off -D LUASTREAM=off -D MAIL=on -D MAIL_IMAP=off -D MAIL_POP3=off \
-D MAIL_SMTP=off -D MAIL_SSL=on -D MEMC=off -D MODSECURITY3=on -D NAXSI=off \
-D NJS=off -D NJS_XML=off -D OTEL=off -D PASSENGER=off -D POSTGRES=off \
-D RDS_CSV=off -D RDS_JSON=off -D REDIS2=on -D RTMP=off -D SET_MISC=off \
-D SFLOW=off -D SHIBBOLETH=off -D SLOWFS_CACHE=off -D SRCACHE=off -D STREAM=on \
-D STREAM_REALIP=on -D STREAM_SSL=on -D STREAM_SSL_PREREAD=on -D STS=off \
-D THREADS=on -D VOD=off -D VTS=off -D WEBSOCKIFY=off -D WWW=on -D XSS=off -D ZSTD=off"

cd /usr/ports/www/nginx-devel
make $NGINX_OPTIONS install clean BATCH=YES

# ==========================================
# 4. ModSecurity OWASP CRS Setup
# ==========================================
log_info "Setting up ModSecurity OWASP CRS..."
mkdir -p /usr/local/etc/modsecurity
cd /tmp
if [ ! -d "owasp-modsecurity-crs" ]; then
    git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
fi
cd owasp-modsecurity-crs
cp crs-setup.conf.example /usr/local/etc/modsecurity/crs-setup.conf
mkdir -p /usr/local/etc/modsecurity/crs
cp rules/* /usr/local/etc/modsecurity/crs/

# Enable Includes
if ! grep -q "Include.*crs.*conf" /usr/local/etc/modsecurity/modsecurity.conf 2>/dev/null; then
    echo 'Include "/usr/local/etc/modsecurity/crs/*.conf"' >> /usr/local/etc/modsecurity/modsecurity.conf
fi

# Disable specific rule being problematic
mv /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf_OFF 2>/dev/null || true

# Copy local security configs
cd "$OLDPWD" # Go back to BeastNgine dir
cp assets/ip_blacklist.txt /usr/local/etc/modsecurity/
cp assets/ip_blacklist.conf /usr/local/etc/modsecurity/
cp assets/unicode.mapping /usr/local/etc/modsecurity/

# Enable Rule Engine
sed -i '' 's/^[[:space:]]*SecRuleEngine DetectionOnly/SecRuleEngine On/' /usr/local/etc/modsecurity/modsecurity.conf

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
cp assets/www.conf /usr/local/etc/php-fpm.d/
# Apply Dynamic PHP Tuning using sed
sed -i '' "s/^pm.max_children.*/pm.max_children = ${PHP_MAX_CHILDREN}/" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s/^pm.start_servers.*/pm.start_servers = ${PHP_START_SERVERS}/" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s/^pm.min_spare_servers.*/pm.min_spare_servers = ${PHP_MIN_SPARE}/" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s/^pm.max_spare_servers.*/pm.max_spare_servers = ${PHP_MAX_SPARE}/" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s/^php_value\[memory_limit\].*/php_value[memory_limit] = ${PHP_MEMORY_LIMIT}/" /usr/local/etc/php-fpm.d/www.conf

# Varnish
mkdir -p /usr/local/etc/varnish
cp assets/wordpress.vcl /usr/local/etc/varnish/

# Valkey
cp assets/valkey.conf /usr/local/etc/

# PHP
mv /usr/local/etc/php.ini-production /usr/local/etc/php.ini-production.bk 2>/dev/null || true
cp assets/php.ini /usr/local/etc/

# Nginx
mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.bk 2>/dev/null || true
cp assets/nginx.conf /usr/local/etc/nginx/
# Apply Dynamic Nginx Tuning
sed -i '' "s/worker_connections [0-9]*;/worker_connections ${NGINX_WORKER_CONNS};/" /usr/local/etc/nginx/nginx.conf

mv /usr/local/etc/nginx/mime.types /usr/local/etc/nginx/mime.types.bk 2>/dev/null || true
cp assets/mime.types /usr/local/etc/nginx/

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
service nginx start
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
