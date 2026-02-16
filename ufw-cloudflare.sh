#!/bin/bash

set -e

SSH_PORT=22
HTTP_PORT=80
HTTPS_PORT=443

echo "Resetting UFW..."
ufw --force reset

echo "Setting default policies..."
ufw default deny incoming
ufw default allow outgoing

echo "Allowing SSH and HTTP..."
ufw allow $SSH_PORT/tcp
ufw allow $HTTP_PORT/tcp

echo "Fetching Cloudflare IP ranges..."
CF_IPV4=$(curl -s https://www.cloudflare.com/ips-v4)
CF_IPV6=$(curl -s https://www.cloudflare.com/ips-v6)

echo "Allowing HTTPS from Cloudflare IPv4..."
for ip in $CF_IPV4; do
    ufw allow from $ip to any port $HTTPS_PORT proto tcp
done

echo "Allowing HTTPS from Cloudflare IPv6..."
for ip in $CF_IPV6; do
    ufw allow from $ip to any port $HTTPS_PORT proto tcp
done

echo "Enabling UFW..."
ufw --force enable

echo "Reloading UFW..."
ufw reload

echo "Done. Current firewall status:"
ufw status verbose
