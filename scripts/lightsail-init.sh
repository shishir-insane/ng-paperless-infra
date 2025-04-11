#!/bin/bash

apt-get update -y
apt-get install -y docker.io docker-compose

usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

mkdir -p /opt/paperless
cd /opt/paperless

# Placeholder for docker-compose.yml, upload separately
touch docker-compose.yml

chown -R ubuntu:ubuntu /opt/paperless
