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

portsnap fetch auto

echo "INSTALLING VARNISH + CERTBOT + PHP80 + MARIADB + SSHGUARD"

pkg install -y php80 php80-mysqli php80-session php80-xml php80-ftp php80-curl php80-tokenizer php80-zlib php80-zip php80-filter php80-gd php80-openssl php80-pdo php80-bcmath php80-exif php80-fileinfo php80-pecl-imagick-im7 php80-curl

pkg install -y mariadb105-client mariadb105-server

pkg install -y py38-certbot-nginx

pkg install -y py38-salt

pkg install -y nano htop git libtool automake autoconf curl geoip

pkg install -y varnish6

cd /usr/ports/security/sshguard

make install clean BATCH=yes

mv /usr/local/etc/sshguard.conf /usr/local/etc/sshguard_bk

cd /usr/local/etc/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/sshguard.conf

pkg install -y libxml2 libxslt modsecurity3 python git binutils pcre libgd openldap-client

echo ""

echo "INSTALLING NGINX WITH MODSECURITY3 AND BROTLI MODULES"

sleep 5

cd

fetch https://github.com/Wamphyre/BeastNgine/raw/master/nginx-devel-1.20.0.txz && pkg install -y nginx-devel-1.20.0.txz

sleep 3

rm -rf nginx-devel-1.20.0.txz

cd /tmp

git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git

cd owasp-modsecurity-crs/

cp crs-setup.conf.example /usr/local/etc/modsecurity/crs-setup.conf

mkdir /usr/local/etc/modsecurity/crs

cp rules/* /usr/local/etc/modsecurity/crs

echo 'Include "/usr/local/etc/modsecurity/crs/*.conf"' >> /usr/local/etc/modsecurity/modsecurity.conf

mv /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf /usr/local/etc/modsecurity/crs/REQUEST-901-INITIALIZATION.conf_OFF

cd /usr/local/etc/modsecurity

fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/ip_blacklist.txt

fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/ip_blacklist.conf

cd /usr/local/etc/modsecurity && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/unicode.mapping
 
sed -ie 's/^\s*SecRuleEngine DetectionOnly/SecRuleEngine On/' /usr/local/etc/modsecurity/modsecurity.conf

echo "Configuring Server Stack..."

sysrc nginx_enable="YES"

sysrc php_fpm_enable="YES"

sysrc varnishd_enable=YES

sysrc varnishd_config="/usr/local/etc/varnish/wordpress.vcl"

sysrc varnishd_listen=":80"

sysrc varnishd_backend="localhost:8080"

sysrc varnishd_storage="malloc,512M"

sysrc varnishd_admin=":8081"

mkdir /usr/local/etc/varnish && cd /usr/local/etc/varnish && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/wordpress.vcl

mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf_bk

mv /usr/local/etc/nginx/mime.types /usr/local/etc/nginx/mime.types_bk

mv /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf_bk

cd /usr/local/etc/php-fpm.d/ && fetch https://raw.githubusercontent.com/Wamphyre/BeastNgine/master/www.conf

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

echo ; read -p "Want to install phpmyadmin?: (yes/no) " PHPMYADMIN;

if [ "$PHPMYADMIN" = "yes" ] 

then cd /usr/local/www/public_html/;

pkg install -y phpMyAdmin-php80

ln -s /usr/local/www/phpMyAdmin/ /usr/local/www/public_html/phpmyadmin

service nginx restart

service php-fpm restart

cd;

else echo "Ignoring phpmyadmin installation" 

fi

echo "Aplying hardening and system tuning"

echo ""

mv /etc/sysctl.conf /etc/sysctl.conf.bk
echo 'vfs.usermount=1' >> /etc/sysctl.conf
echo 'vfs.vmiodirenable=0' >> /etc/sysctl.conf
echo 'vfs.read_max=4' >> /etc/sysctl.conf
echo 'kern.ipc.shmmax=67108864' >> /etc/sysctl.conf
echo 'kern.ipc.shmall=32768' >> /etc/sysctl.conf
echo 'kern.ipc.somaxconn=256' >> /etc/sysctl.conf
echo 'kern.ipc.shm_use_phys=1' >> /etc/sysctl.conf
echo 'kern.ipc.somaxconn=32' >> /etc/sysctl.conf
echo 'kern.maxvnodes=60000' >> /etc/sysctl.conf
echo 'kern.coredump=0' >> /etc/sysctl.conf
echo 'kern.sched.preempt_thresh=224' >> /etc/sysctl.conf
echo 'kern.sched.slice=3' >> /etc/sysctl.conf
echo 'hw.snd.feeder_rate_quality=3' >> /etc/sysctl.conf
echo 'hw.snd.maxautovchans=32' >> /etc/sysctl.conf
echo 'vfs.lorunningspace=1048576' >> /etc/sysctl.conf
echo 'vfs.hirunningspace=5242880' >> /etc/sysctl.conf
echo 'kern.ipc.shm_allow_removed=1' >> /etc/sysctl.conf
echo 'hw.snd.vpc_autoreset=0' >> /boot/loader.conf
echo 'hw.syscons.bell=0' >> /boot/loader.conf
echo 'hw.usb.no_pf=1' >> /boot/loader.conf
echo 'hw.usb.no_boot_wait=0' >> /boot/loader.conf
echo 'hw.usb.no_shutdown_wait=1' >> /boot/loader.conf
echo 'hw.psm.synaptics_support=1' >> /boot/loader.conf
echo 'kern.maxfiles="25000"' >> /boot/loader.conf
echo 'kern.maxusers=16' >> /boot/loader.conf
echo 'kern.cam.scsi_delay=10000' >> /boot/loader.conf

sysrc pf_enable="YES"
sysrc pf_rules="/etc/pf.conf" 
sysrc pf_flags=""
sysrc pflog_enable="YES"
sysrc pflog_logfile="/var/log/pflog"
sysrc pflog_flags=""
sysrc ntpd_enable="YES"
sysrc ntpdate_enable="YES"
sysrc powerd_enable="YES"
sysrc powerd_flags="-a hiadaptive"
performance_cpu_freq="HIGH"
sysrc clear_tmp_enable="YES"
sysrc syslogd_flags="-ss"
sysrc sendmail_enable="YES"
sysrc dumpdev="NO"
sysrc sshguard_enable="YES"

echo 'kern.elf64.nxstack=1' >> /etc/sysctl.conf
echo 'security.bsd.map_at_zero=0' >> /etc/sysctl.conf
echo 'security.bsd.see_other_uids=0' >> /etc/sysctl.conf
echo 'security.bsd.see_other_gids=0' >> /etc/sysctl.conf
echo 'security.bsd.unprivileged_read_msgbuf=0' >> /etc/sysctl.conf
echo 'security.bsd.unprivileged_proc_debug=0' >> /etc/sysctl.conf
echo 'kern.randompid=9800' >> /etc/sysctl.conf
echo 'security.bsd.stack_guard_page=1' >> /etc/sysctl.conf
echo 'net.inet.udp.blackhole=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.blackhole=2' >> /etc/sysctl.conf
echo 'net.inet.ip.random_id=1' >> /etc/sysctl.conf

echo ""

echo "Optimizing FreeBSD network stack settings"

echo ""

echo 'kern.ipc.soacceptqueue=1024' >> /etc/sysctl.conf
echo 'kern.ipc.maxsockbuf=8388608' >> /etc/sysctl.conf
echo 'net.inet.tcp.sendspace=262144' >> /etc/sysctl.conf
echo 'net.inet.tcp.recvspace=262144' >> /etc/sysctl.conf
echo 'net.inet.tcp.sendbuf_max=16777216' >> /etc/sysctl.conf
echo 'net.inet.tcp.recvbuf_max=16777216' >> /etc/sysctl.conf
echo 'net.inet.tcp.sendbuf_inc=32768' >> /etc/sysctl.conf
echo 'net.inet.tcp.recvbuf_inc=65536' >> /etc/sysctl.conf
echo 'net.inet.raw.maxdgram=16384' >> /etc/sysctl.conf
echo 'net.inet.raw.recvspace=16384' >> /etc/sysctl.conf
echo 'net.inet.tcp.abc_l_var=44' >> /etc/sysctl.conf
echo 'net.inet.tcp.initcwnd_segments=44' >> /etc/sysctl.conf
echo 'net.inet.tcp.mssdflt=1448' >> /etc/sysctl.conf
echo 'net.inet.tcp.minmss=524' >> /etc/sysctl.conf
echo 'net.inet.tcp.cc.algorithm=htcp' >> /etc/sysctl.conf
echo 'net.inet.tcp.cc.htcp.adaptive_backoff=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.cc.htcp.rtt_scaling=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.rfc6675_pipe=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.syncookies=0' >> /etc/sysctl.conf
echo 'net.inet.tcp.nolocaltimewait=1' >> /etc/sysctl.conf
echo 'net.inet.tcp.tso=0' >> /etc/sysctl.conf
echo 'net.inet.ip.intr_queue_maxlen=2048' >> /etc/sysctl.conf
echo 'net.route.netisr_maxqlen=2048' >> /etc/sysctl.conf
echo 'dev.igb.0.fc=0' >> /etc/sysctl.conf
echo 'dev.igb.1.fc=0' >> /etc/sysctl.conf
echo 'aio_load="yes"' >> /boot/loader.conf
echo 'cc_htcp_load="YES"' >> /boot/loader.conf
echo 'accf_http_load="YES"' >> /boot/loader.conf
echo 'accf_data_load="YES"' >> /boot/loader.conf
echo 'accf_dns_load="YES"' >> /boot/loader.conf
echo 'net.inet.tcp.hostcache.cachelimit="0"' >> /boot/loader.conf
echo 'net.link.ifqmaxlen="2048"' >> /boot/loader.conf
echo 'net.inet.tcp.soreceive_stream="1"' >> /boot/loader.conf
echo 'hw.igb.rx_process_limit="-1"' >> /boot/loader.conf
echo 'ahci_load="YES"' >> /boot/loader.conf
echo 'coretemp_load="YES"' >> /boot/loader.conf
echo 'tmpfs_load="YES"' >> /boot/loader.conf
echo 'if_igb_load="YES"' >> /boot/loader.conf

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
