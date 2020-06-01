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

# the external network interface to the internet
ext_if="'$INTERFAZ'"
# port on which sshd is running
ssh_port = "3333"
# allowed inbound ports (services hosted by this machine)
inbound_tcp_services = "{80, 443, 21, 25, 3333}"
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
pass in on $ext_if proto tcp from any to 108.61.176.8 port 21 flags S/SA synproxy state
pass in on $ext_if proto tcp from any to 108.61.176.8 port > 49151 keep state
# keep stats of outgoing connections
pass out keep state
' >> /etc/pf.conf

service pf reload

echo ""

echo "ATTACK MODE DEACTIVATED"
