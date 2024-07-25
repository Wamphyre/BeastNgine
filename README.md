# BeastNgine

Engintron inspired implementation of Varnish, Nginx, PHP83, PHP-FPM and Valkey **for FreeBSD**

This only installs a very customized, secure and optimized web server stack, especially oriented to Wordpress installations

Keep in mind that this will not install DNS servers or Mail servers

For DNS you can simply use Cloudflare, or your VPS provider DNS, even glue records on your domain registrar

**--- PRE-INSTALLATION --**

Please, install it ONLY in clean FreeBSD installations to avoid some compatibility troubles

Changing FreeBSD pkg repo from "quarterly" to "latest" is required

You can do it editing the file `/usr/local/etc/pkg.conf`

Don't forget to install htop, git, nano, curl and wget: `pkg install curl wget htop nano git`

**--- INSTALLATION ---**

1 - Clone the repo: `git clone https://github.com/Wamphyre/BeastNgine`

2 - Enter into the directory: `cd BeastNgine/`

3 - Launch beastngine_install.sh and FOLLOW CAREFULLY the instructions: `sh beastngine_install.sh`

4 - Once the installation is complete, restart your server

**--- POST-INSTALLATION ---**

0 - Launch `generate_ssl_key_sendmail.sh`

1 - OPTIONAL: Change your SSH access port and use the same for `/etc/pf.conf firewall`

2 - Add your hostname to `/etc/hosts`

3 - Launch `add_domain.sh` script to create a VHOST for a domain, this will create his own directory on `/usr/local/www/public_html` and his own pre-configured VHOST on `/usr/local/etc/nginx/conf.d`

**WARNING** FIRST, check the script and change the ssh default port to yours
