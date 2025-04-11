#!/bin/bash
# cloud-init script for provisioning a Paperless-ngx host

set -eux

echo "📦 Updating packages..."
apt update -y
apt upgrade -y

echo "🐳 Installing Docker and Docker Compose..."
apt install -y docker.io docker-compose

echo "🌐 Installing Nginx and Certbot..."
apt install -y nginx certbot python3-certbot-nginx ufw

echo "🔐 Configuring UFW firewall..."
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

echo "📁 Preparing /opt/paperless directory..."
mkdir -p /opt/paperless
chown root:root /opt/paperless

echo "✅ Init complete. Ready for GitHub Actions to deploy."
