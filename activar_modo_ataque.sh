#!/bin/bash

clear

echo "Mostrando interfaces de red disponibles"

echo ""

ifconfig | grep :

echo ""

echo ; read -p "¿Para qué interfaz quieres configurar las reglas?: " INTERFAZ;

echo ""

rm -rf /etc/pf.conf

touch /etc/pf.conf

echo '

#MODO ATAQUE ACTIVADO
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

echo "MODO ATAQUE ACTIVADO"
