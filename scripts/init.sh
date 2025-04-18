#!/bin/bash
# cloud-init script for provisioning a Paperless-ngx host

set -e

echo "🔧 Running paperless init.sh..."

# Create the target mount point
mkdir -p /opt/paperless/data

# Check if already mounted
if mountpoint -q /opt/paperless/data; then
  echo "✅ Volume already mounted at /opt/paperless/data"
else
  echo "🔌 Attempting to mount attached volume..."

  # Find attached volume device
  DEVICE=$(lsblk -o NAME,MOUNTPOINT | grep -v part | grep -v '/boot' | grep -v '/$' | awk '{print $1}' | head -n1)

  if [ -n "$DEVICE" ]; then
    echo "🔍 Found device: /dev/$DEVICE"
    mount "/dev/$DEVICE" /opt/paperless/data || echo "⚠️ Mount failed, device may not be ready."
  else
    echo "❌ No suitable volume found to mount!"
  fi
fi

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
