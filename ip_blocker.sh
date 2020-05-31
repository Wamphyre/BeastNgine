#!/bin/bash

clear

echo "Showing IPs with more recursive connections"

echo ""

cd /var/log/nginx

awk '{print $1 }' access.log | sort | uniq -c | sort -nr | head -20

echo ""

echo ; read -p "Which IP you want to block? " IP;

echo ""

/sbin/route add $IP 127.0.0.1 -blackhole

echo ""

echo "$IP blocked forever"
