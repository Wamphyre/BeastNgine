#!/bin/bash

clear

echo "Mostrando IPs con más conexiones"

echo ""

cd /var/log/nginx

awk '{print $1 }' access.log | sort | uniq -c | sort -nr | head -20

echo ""

echo ; read -p "Dime IP a bloquear " IP;

echo ""

/sbin/route add $IP 127.0.0.1 -blackhole

echo ""

echo "$IP bloqueada para siempre"
