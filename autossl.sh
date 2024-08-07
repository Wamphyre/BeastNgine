#!/bin/bash

clear

echo "AutoSSL Installer"

sleep 1

echo ""

echo ; read -p "Give me a domain for SSL key: " DOMINIO;

echo ""

service varnishd stop

sleep 3

sed -i '' -e 's/^[[:space:]]*listen 8080/listen 80/' /usr/local/etc/nginx/nginx.conf
sed -i '' -e 's/^[[:space:]]*listen 8080/listen 80/' /usr/local/etc/nginx/conf.d/$DOMINIO.conf

rm -rf /usr/local/etc/nginx/nginx.confe

rm -rf /usr/local/etc/nginx/conf.d/$DOMINIO.confe

service nginx restart

sleep 3

certbot-3.9 --nginx -d $DOMINIO

echo ""

service nginx restart

sleep 2

echo ""

certbot-3.9 enhance --hsts -d $DOMINIO

echo ""

sleep 2

service nginx restart

echo ""

sed -i '' -e 's/^[[:space:]]*listen 80/listen 8080/' /usr/local/etc/nginx/nginx.conf
sed -i '' -e 's/^[[:space:]]*listen 80/listen 8080/' /usr/local/etc/nginx/conf.d/$DOMINIO.conf
sed -i '' -e 's/^[[:space:]]*443 ssl/443 ssl http2/' /usr/local/etc/nginx/conf.d/$DOMINIO.conf

rm -rf /usr/local/etc/nginx/nginx.confe

rm -rf /usr/local/etc/nginx/conf.d/$DOMINIO.confe

service nginx restart

sleep 3

service varnishd restart

echo "Process completed"
