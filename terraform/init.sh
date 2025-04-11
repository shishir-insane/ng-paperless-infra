#!/bin/bash

apt-get update -y
apt-get install -y docker.io docker-compose

usermod -aG docker root
systemctl enable docker
systemctl start docker

mkdir -p /opt/paperless
chown -R root:root /opt/paperless

# You'll later SCP your docker-compose.yml here or use remote-exec
