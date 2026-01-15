# BeastNgine

**High-Performance FreeBSD Web Stack optimized for WordPress**

BeastNgine is an automated deployment suite for FreeBSD, inspired by Engintron but tailored for the BSD ecosystem. It deploys a highly specific, security-hardened, and performance-tuned stack consisting of Varnish Cache (Warning: advanced configuration), Nginx, PHP-FPM, MariaDB, and Valkey (Redis fork).

## 🚀 Features

*   **OS**: FreeBSD 13/14+ Support
*   **Dynamic Tuning**: Automatically detects your Hardware (RAM/CPU) and tunes:
    *   Kernel Parameters (`sysctl.conf`, `/boot/loader.conf`)
    *   IP/TCP Stack (Congestion control, buffers)
    *   Database Buffers (`innodb_buffer_pool`)
    *   Varnish Storage Size
    *   PHP-FPM Workers & Nginx Connections
*   **Security**:
    *   ModSecurity v3 with OWASP CRS (Pre-configured)
    *   PF Firewall (Packet Filter) with aggressive rules
    *   SshGuard integration
    *   Bot & Spam Blocking
*   **Stack**:
    *   **Frontend**: Varnish Cache (Port 80)
    *   **Backend**: Nginx (Port 8080) with Brotli & ModSecurity
    *   **App**: PHP 8.x + FPM (Dynamic Pools)
    *   **DB**: MariaDB 10.x / 11.x
    *   **Object Cache**: Valkey

## 📋 Requirements

*   Fresh installation of **FreeBSD** (Clean install recommended).
*   Root privileges.
*   Pkg repository configured to `latest` (recommended).

## 🛠️ Installation

1.  **Clone the repository**:
    ```sh
    git clone https://github.com/Wamphyre/BeastNgine
    cd BeastNgine
    ```

2.  **Run the Installer**:
    ```sh
    sh beastngine_install.sh
    ```
    *   *Follow the on-screen instructions carefully. You will be asked to select your network interface for the firewall.*

3.  **Restart**:
    Once finished, restart your server to apply kernel and boot loader changes.
    ```sh
    reboot
    ```

## 🔧 Post-Installation & Helpers

All utility scripts are located in the `helpers/` directory.

### 1. Add a Domain
Create a new Virtual Host optimized for WordPress.
```sh
sh helpers/add_domain.sh
# OR for WP Rocket users:
sh helpers/add_domain_with_rocket_nginx.sh
```

### 2. Install SSL (Let's Encrypt)
Automaticaly obtains a certificate, handling the Varnish port conflict for you.
```sh
sh helpers/autossl.sh
```

### 3. Database Backups
Create a full backup (Files + SQL) of a domain. Auto-detects credentials from `wp-config.php`.
```sh
sh helpers/backup_creator.sh
```

### 4. Security
*   **Block IP**: Permanently block an IP using PF tables.
    ```sh
    sh helpers/ip_blocker.sh
    ```
*   **Generate Mail Certs**:
    ```sh
    sh helpers/generate_ssl_key_sendmail.sh
    ```

### 5. Maintenance
*   **Update System**: `sh helpers/updater.sh`
*   **Fix Permissions**: `sh helpers/repair_permissions.sh`

## 📂 Directory Structure

*   `/usr/local/etc/nginx/conf.d/` - Nginx VHOSTs
*   `/usr/local/www/public_html/` - Web Root
*   `assets/` - Default configuration templates (Nginx, PHP, ModSec)
*   `helpers/` - Management scripts

## ⚠️ Important Notes

*   **DNS**: This stack does NOT install a DNS server. Use Cloudflare or your registrar's DNS.
*   **Mail**: This stack disables Sendmail by default to save resources. Use an external SMTP service (Mailgun, Sendgrid, etc.).
*   **Firewall**: The PF rules are strict. Ensure you define your SSH port correctly if you change it from 22.

---
*By Wamphyre*
