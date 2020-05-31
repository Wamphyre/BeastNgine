#!/bin/bash

clear

echo "Showing net interfaces"

echo ""

ifconfig | grep :

echo ""

echo ; read -p "Please, select a network interface: " INTERFAZ;

echo ""

rm -rf /etc/pf.conf

touch /etc/pf.conf

echo '

#ATTACK MODE ACTIVATED
# the external network interface to the internet
ext_if="'$INTERFAZ'"
# port on which sshd is running
ssh_port = "3333"
# allowed inbound ports (services hosted by this machine)
inbound_tcp_services = "{3333}"
block in all
pass out all keep state' >> /etc/pf.conf

service pf reload

echo ""

echo "ATTACK MODE ACTIVATED, BLOCKING ALL TRAFFIC"
