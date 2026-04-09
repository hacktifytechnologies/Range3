#!/bin/bash
# ============================================================
# AETHON Range — Machine 1 (aethon-web) Setup Script
# Challenge: XXE Injection on Procurement Portal
# OS: Ubuntu 22.04 LTS
# ============================================================
set -e

echo "[*] AETHON Range — M1 Web Portal Setup"
echo "[*] Setting hostname..."
hostnamectl set-hostname aethon-web

echo "[*] Updating packages..."
apt-get update -qq

echo "[*] Installing Apache2 + PHP 8.1..."
apt-get install -y apache2 php8.1 libapache2-mod-php8.1 php8.1-xml php8.1-common -qq

echo "[*] Enabling Apache mod_rewrite..."
a2enmod rewrite

echo "[*] Deploying web application..."
WEBROOT="/var/www/html"
rm -f $WEBROOT/index.html

# Copy webapp files
cp -r /opt/aethon-setup/webapp/* $WEBROOT/
chown -R www-data:www-data $WEBROOT/

echo "[*] Setting permissions — config dir readable by www-data..."
chmod 750 $WEBROOT/config/
chmod 640 $WEBROOT/config/internal.xml
chown -R www-data:www-data $WEBROOT/config/

echo "[*] Planting Flag 1..."
echo "AETHON{xxe_r34ds_4ll_s3cr3ts_v3nd0r}" > /etc/flag1.txt
chmod 644 /etc/flag1.txt

echo "[*] Configuring Apache virtual host..."
cat > /etc/apache2/sites-available/aethon-portal.conf << 'VHEOF'
<VirtualHost *:80>
    ServerName aethon-web
    DocumentRoot /var/www/html
    DirectoryIndex index.html

    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>

    <Directory /var/www/html/config>
        Require all denied
    </Directory>

    <FilesMatch "\.php$">
        SetHandler application/x-httpd-php
    </FilesMatch>

    ErrorLog ${APACHE_LOG_DIR}/aethon_error.log
    CustomLog ${APACHE_LOG_DIR}/aethon_access.log combined
</VirtualHost>
VHEOF

a2dissite 000-default.conf 2>/dev/null || true
a2ensite aethon-portal.conf
systemctl enable apache2
systemctl restart apache2

echo "[*] Setting up /etc/hosts entries (uses actual assigned IPs from OpenStack DHCP)..."
# NOTE: Do NOT hardcode IPs. These are populated by cloud-init/DHCP at boot.
# Participants discover internal hosts via XXE reading /etc/hosts
# The admin should ensure all VMs are named: aethon-web, aethon-docs, aethon-dev, aethon-cache, aethon-core
# OpenStack Neutron DNS will resolve these hostnames within the same network segment.

echo "[*] Verifying Apache is up..."
sleep 2
systemctl status apache2 --no-pager | head -5

echo ""
echo "=============================================="
echo " M1 (aethon-web) SETUP COMPLETE"
echo " Web portal accessible on port 80"
echo " Flag 1: /etc/flag1.txt"
echo " XXE target: /var/www/html/config/internal.xml"
echo "=============================================="
