#!/bin/bash
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
