# BeastNgine
Engintron inspired implementation of Varnish, Nginx, php-fpm, certbot and modsecurity for FreeBSD

This only installs a very customized, secure and optimized web server stack, especially oriented to Wordpress installations

Keep in mind that this will not install DNS servers or Mail servers

For DNS you can simply use Cloudflare, or your VPS provider DNS, even glue records on your domain registrar

--- PRE-INSTALLATION --

Please, install it ONLY in clean FreeBSD installations to avoid some compatibility troubles

Changing FreeBSD pkg repo from "quarterly" to "latest" is required

You can do it editing the file /usr/local/etc/pkg.conf

Don't forget to install htop, git, nano, curl and wget: pkg install curl wget htop nano git

--- INSTALLATION ---

1 - Clone the repo: git clone https://github.com/Wamphyre/BeastNgine

2 - Enter into the directory: cd BeastNgine/

3 - Launch beastngine_install.sh and FOLLOW CAREFULLY the instructions: sh beastngine_install.sh

4 - Once the installation is complete, restart your server

--- POST-INSTALLATION ---

0 - Launch generate_ssl_key_sendmail.sh

1 - OPTIONAL: Change your SSH access port and use the same for /etc/pf.conf firewall

2 - Add your hostname to /etc/hosts

3 - Launch add_domain.sh script to create a VHOST for a domain, this will create his own directory on /usr/local/www/public_html and his own pre-configured VHOST on /usr/local/etc/nginx/conf.d

4 - If the domain have DNS set up, launch autossl.sh script to install an SSL certificate 

5 - Start working on your website

6 - If you need to create databases, you can access phpmyadmin using domain.com/phpmyadmin

7 - If you're under attack, just launch attack_mode_on.sh script to block ALL TRAFFIC, launch attack_mode_off.sh to deactivate

8 - You can block IPs too with the ip_blocker.sh script

9 - You can update your system launching updater.sh script

10 - You can clean your pkg and ports tmp files using port_cleaner.sh script

11 - You can repair permissions on the public directory (/usr/local/www/public_html) with the repair_permissions.sh script

12 - You can optimize images of your website with the image_optimizer.sh script

13 - You can install wordpress inside a directory on public_html with the autowordpress.sh script

14 - You can make backups of your Wordpress (with sql database included), with the backup_creator.sh script
