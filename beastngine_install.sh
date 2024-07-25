#!/bin/bash

clear

echo "=====BeastNgine Server for FreeBSD====="

echo "----------------------by Wamphyre"

echo ""

sleep 3

echo "Updating packages..."

echo ""

pkg update && pkg upgrade -y 

echo ""

echo "Packages updated" 

echo ""

echo "Extracting ports..."

echo ""

git clone --depth 1 https://git.FreeBSD.org/ports.git /usr/ports

echo "INSTALLING PHP83 / VARNISH / VALKEY / MARIADB / CERTBOT / SSHGUARD"

pkg install -y php83 php83-bcmath php83-ctype php83-curl php83-dom php83-exif php83-fileinfo php83-filter php83-ftp php83-gd php83-iconv php83-intl php83-mbstring php83-mysqli php83-opcache php83-pdo php83-pecl-redis php83-session php83-tokenizer php83-xml php83-zip php83-zlib
pkg install -y mariadb106-client mariadb106-server
pkg install -y py39-certbot-nginx py39-certbot
pkg install -y nano htop git libtool automake autoconf curl
pkg install -y varnish7
pkg install -y valkey

cd /usr/ports/security/sshguard && make install clean BATCH=yes

mv /usr/local/etc/sshguard.conf /usr/local/etc/sshguard_bk

cd /usr/local/etc/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/sshguard.conf

pkg install -y libxml2 libxslt modsecurity3 python git binutils pcre libgd

echo ""

echo "COMPILING NGINX WITH MODSECURITY3 AND BROTLI MODULES"

sleep 3

cd

cd /usr/ports/www/nginx-devel && make -D AJP=off -D ARRAYVAR=off -D AWS_AUTH=off -D BROTLI=on -D CACHE_PURGE=on -D CT=off -D DEBUG=off -D DEBUGLOG=off -D DEVEL_KIT=off -D DRIZZLE=off -D DSO=on -D DYNAMIC_UPSTREAM=off -D ECHO=off -D ENCRYPTSESSION=off -D FILE_AIO=on -D FIPS_CHECK=off -D FORMINPUT=off -D GOOGLE_PERFTOOLS=off -D GRIDFS=off -D GSSAPI_HEIMDAL=off -D GSSAPI_MIT=off -D HEADERS_MORE=off -D HTTP=on -D HTTPV2=on -D HTTPV3=on -D HTTPV3_BORING=off -D HTTPV3_LSSL=off -D HTTPV3_QTLS=off -D HTTP_ACCEPT_LANGUAGE=off -D HTTP_ADDITION=on -D HTTP_AUTH_DIGEST=off -D HTTP_AUTH_KRB5=off -D HTTP_AUTH_LDAP=off -D HTTP_AUTH_PAM=off -D HTTP_AUTH_REQ=on -D HTTP_CACHE=on -D HTTP_DAV=on -D HTTP_DAV_EXT=off -D HTTP_DEGRADATION=off -D HTTP_EVAL=off -D HTTP_FANCYINDEX=off -D HTTP_FLV=on -D HTTP_FOOTER=off -D HTTP_GEOIP2=on -D HTTP_GUNZIP_FILTER=on -D HTTP_GZIP_STATIC=on -D HTTP_IMAGE_FILTER=on -D HTTP_IP2LOCATION=on -D HTTP_IP2PROXY=on -D HTTP_JSON_STATUS=off -D HTTP_MOGILEFS=off -D HTTP_MP4=on -D HTTP_NOTICE=off -D HTTP_PERL=off -D HTTP_PUSH=off -D HTTP_PUSH_STREAM=off -D HTTP_RANDOM_INDEX=on -D HTTP_REALIP=on -D HTTP_REDIS=on -D HTTP_SECURE_LINK=on -D HTTP_SLICE=on -D HTTP_SLICE_AHEAD=off -D HTTP_SSL=on -D HTTP_STATUS=on -D HTTP_SUB=on -D HTTP_SUBS_FILTER=off -D HTTP_TARANTOOL=off -D HTTP_UPLOAD=off -D HTTP_UPLOAD_PROGRESS=off -D HTTP_UPSTREAM_CHECK=off -D HTTP_UPSTREAM_FAIR=off -D HTTP_UPSTREAM_STICKY=off -D HTTP_VIDEO_THUMBEXTRACTOR=off -D HTTP_XSLT=on -D HTTP_ZIP=off -D ICONV=off -D IPV6=on -D LET=off -D LINK=off -D LUA=off -D LUASTREAM=off -D MAIL=on -D MAIL_IMAP=off -D MAIL_POP3=off -D MAIL_SMTP=off -D MAIL_SSL=on -D MEMC=off -D MODSECURITY3=on -D NAXSI=off -D NJS=off -D NJS_XML=off -D OTEL=off -D PASSENGER=off -D POSTGRES=off -D RDS_CSV=off -D RDS_JSON=off -D REDIS2=on -D RTMP=off -D SET_MISC=off -D SFLOW=off -D SHIBBOLETH=off -D SLOWFS_CACHE=off -D SRCACHE=off -D STREAM=on -D STREAM_REALIP=on -D STREAM_SSL=on -D STREAM_SSL_PREREAD=on -D STS=off -D THREADS=on -D VOD=off -D VTS=off -D WEBSOCKIFY=off -D WWW=on -D XSS=off -D ZSTD=off install clean BATCH=YES

cd /tmp && git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git

cd owasp-modsecurity-crs/ && cp crs-setup.conf.example /usr/local/etc/modsecurity/crs-setup.conf

mkdir /usr/local/etc/modsecurity/crs && cp rules/* /usr/local/etc/modsecurity/crs

echo 'Include "/usr/local/etc/modsecurity/crs/*.conf"' >> /usr/local/etc/modsecurity/modsecurity.conf

mv /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf_OFF

cd /usr/local/etc/modsecurity

fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/ip_blacklist.txt

fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/ip_blacklist.conf

cd /usr/local/etc/modsecurity && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/unicode.mapping
 
sed -i '' 's/^[[:space:]]*SecRuleEngine DetectionOnly/SecRuleEngine On/' /usr/local/etc/modsecurity/modsecurity.conf

echo "Configuring Server Stack..."

sysrc nginx_enable="YES"
sysrc php_fpm_enable="YES"
sysrc varnishd_enable=YES
sysrc varnishd_config="/usr/local/etc/varnish/wordpress.vcl"
sysrc varnishd_listen=":80"
sysrc varnishd_backend="localhost:8080"
sysrc varnishd_storage="malloc,128M"
sysrc varnishd_admin=":8081"
sysrc valkey_enable="YES"

mkdir /var/log/php-fpm

mkdir /usr/local/etc/varnish && cd /usr/local/etc/varnish && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/wordpress.vcl

mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf_bk

mv /usr/local/etc/nginx/mime.types /usr/local/etc/nginx/mime.types_bk

mv /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf_bk

cd /usr/local/etc/php-fpm.d/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/www.conf

cd /usr/local/etc/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/valkey.conf

cd /usr/local/etc/nginx/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/nginx.conf

cd /usr/local/etc/nginx/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/mime.types

mkdir conf.d

touch /usr/local/etc/nginx/conf.d/default_vhost.conf && cd /usr/local/etc/nginx/conf.d/

DOMINIO=$(hostname)

echo "

server {
listen 8080;
listen [::]:8080;

server_name $DOMINIO www.$DOMINIO;

root /usr/local/www/public_html;
index index.php index.html;
    
    resolver                   1.1.1.1;
    # allow POSTs to static pages
    error_page                 405    =200 \$uri;
    access_log                 /var/log/nginx/$DOMINIO-access.log;
    error_log                  /var/log/nginx/$DOMINIO-error.log;

        location / {
                # This is cool because no php is touched for static content.
                # include the "\$is_args\$args" so non-default permalinks doesn't break when using query string
                try_files \$uri \$uri/ /index.php\$is_args\$args;
        }
	
	 # deny access to xmlrpc.php which allows brute-forcing at a higher rates
        # than wp-login.php; this may break some functionality, like WordPress
        # iOS/Android app posting 
        location ~* /xmlrpc\.php {
            deny                        all;
        }

# Media: images, icons, video, audio, HTC
location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)\$ {
	expires 1M;
	access_log off;
	add_header Cache-Control "public";
}

# CSS and Javascript
location ~* \.(?:css|js)\$ {
	expires 1y;
	access_log off;
	add_header Cache-Control "public";
}

location = ^/favicon.ico {
    access_log off;
    log_not_found off;
}

# robots noise...
location = ^/robots.txt {
    log_not_found off;
    access_log off;
    allow all;
}

# block access to hidden files (.htaccess per example)
location ~ /\. { access_log off; log_not_found off; deny all; }

     location ~ [^/]\.php(/|$) {
        root	/usr/local/www/public_html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param SCRIPT_FILENAME \$request_filename;    
        include        fastcgi_params;
        	}
}
" >> default_vhost.conf

service nginx start

service varnishd start

service valkey start

mv /usr/local/etc/php.ini-production /usr/local/etc/php.ini-production_bk

cd /usr/local/etc/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/php.ini

mkdir /usr/local/www/public_html/

cd /usr/local/www/public_html/

chown -R www:www /usr/local/www/public_html/

echo ""

sysrc mysql_enable="YES"
sysrc mysql_args="--bind-address=127.0.0.1"

service mysql-server start

sleep 5

/usr/local/bin/mysql_secure_installation

echo "Aplying hardening and system tuning"

echo ""

# Parámetros a añadir
params="
# Mejorar el rendimiento del sistema de archivos
vfs.read_max=128
# Ajustes de caché de directorio
vfs.cache.maxvnodes=50000
# Habilitar uso de todos los núcleos del CPU
kern.sched.steal_cores=1
# Optimización de memoria
vm.pmap.sp_enabled=1
# Incrementar la cantidad de sockets disponibles para conexiones web
kern.ipc.somaxconn=3048
# Ajustes para el rendimiento de red
net.inet.tcp.mssdflt=1460
net.inet.tcp.minmss=536
net.inet.tcp.cc.algorithm=cubic
# Desactivar envío de RST al puerto cerrado
net.inet.tcp.blackhole=2
net.inet.udp.blackhole=1
# Configuración adicional
kern.coredump=0
kern.sched.preempt_thresh=224
vfs.usermount=1
vfs.vmiodirenable=0
"

# Añadir los parámetros al archivo sysctl.conf
echo "$params" >> /etc/sysctl.conf

# Parámetros a añadir
params="
# Configure USB OTG; see usb_template(4).
hw.usb.template=3
umodem_load=\"YES\"

# Multiple console (serial+efi gop) enabled.
boot_multicons=\"YES\"
boot_serial=\"YES\"

# Disable the beastie menu and color
beastie_disable=\"YES\"
loader_color=\"NO\"
"

# Añadir los parámetros al archivo loader.conf
echo "$params" >> /boot/loader.conf

params="
[mysqld]
# Parámetros de configuración iniciales
key_buffer_size         = 8M
max_allowed_packet      = 16M
thread_stack            = 192K
thread_cache_size       = 8
query_cache_limit       = 512K
query_cache_size        = 8M

# Cambiar el motor de almacenamiento predeterminado a InnoDB
default-storage-engine  = innodb

# Configuraciones de InnoDB
innodb_buffer_pool_size = 128M  # Reducido para ajustarse a 1 GB de RAM
innodb_log_file_size    = 32M   # Ajustado para uso moderado de RAM
innodb_flush_log_at_trx_commit = 1
innodb_file_per_table   = 1

# Tamaño máximo permitido del paquete
max_allowed_packet      = 16M

# Número máximo de conexiones
max_connections         = 50    # Reducido para ajustarse a 1 GB de RAM
"

# Añadir los parámetros al archivo my.cnf
echo "$params" >> /usr/local/etc/mysql/my.cnf

sysrc pf_enable="YES"
sysrc pf_rules="/etc/pf.conf" 
sysrc pf_flags=""
sysrc pflog_enable="YES"
sysrc pflog_logfile="/var/log/pflog"
sysrc pflog_flags=""
sysrc ntpd_enable="YES"
sysrc ntpdate_enable="YES"
sysrc performance_cx_lowest="Cmax"
sysrc economy_cx_lowest="Cmax"
sysrc clear_tmp_enable="YES"
sysrc syslogd_flags="-ss"
sysrc sendmail_submit_enable="NO"
sysrc sendmail_msp_queue_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_enable="NO"
sysrc dumpdev="NO"
sysrc sshguard_enable="YES"

echo ""

echo "Updating CPU microcode"

echo ""

pkg install -y devcpu-data

sysrc microcode_update_enable="YES"

service microcode_update start

echo ""

echo "Microcode updated"

echo ""

echo "Setting up PF firewall"

echo ""

touch /etc/pf.conf

echo "Showing network interfaces"

echo ""

ifconfig | grep :

echo ""

echo ; read -p "Please, select a network interface: " INTERFAZ;

echo ""

echo '# the external network interface to the internet
ext_if="'$INTERFAZ'"
# port on which sshd is running
ssh_port = "22"
# allowed inbound ports (services hosted by this machine)
inbound_tcp_services = "{80, 443, 21, 25," $ssh_port " }"
inbound_udp_services = "{80, 8080, 443}"
# politely send TCP RST for blocked packets. The alternative is
# "set block-policy drop", which will cause clients to wait for a timeout
# before giving up.
set block-policy return
# log only on the external interface
set loginterface $ext_if
# skip all filtering on localhost
set skip on lo
# reassemble all fragmented packets before filtering them
scrub in on $ext_if all fragment reassemble
# block forged client IPs (such as private addresses from WAN interface)
antispoof for $ext_if
# default behavior: block all traffic
block all
# allow all icmp traffic (like ping)
pass quick on $ext_if proto icmp
pass quick on $ext_if proto icmp6
# allow incoming traffic to services hosted by this machine
pass in quick on $ext_if proto tcp to port $inbound_tcp_services
pass in quick on $ext_if proto udp to port $inbound_udp_services
# allow all outgoing traffic
pass out quick on $ext_if
table <sshguard> persist
block in quick on $ext_if from <sshguard>' >> /etc/pf.conf

IP=$(curl ifconfig.me)

echo "pass in on \$ext_if proto tcp from any to $IP port 21 flags S/SA synproxy state
pass in on \$ext_if proto tcp from any to $IP port > 49151 keep state
# keep stats of outgoing connections
pass out keep state" >> /etc/pf.conf

echo ""

kldload pf
service sshguard start

echo "Firewall rules configured for $INTERFAZ"

echo ""

echo "Cleaning system..."

echo ""

pkg clean -y && pkg autoremove -y

echo ""

echo "Installation finished, please restart your system"
