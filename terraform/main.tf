terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.50.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "hcloud" {
  token = var.hcloud_token
  
  # Add retry configuration
  retry = {
    max_retries = var.provider_retry_max_retries
    min_retry_delay = var.provider_retry_min_delay
    max_retry_delay = var.provider_retry_max_delay
  }
  
  # Add debug logging
  debug = true
}

# SSH Key
resource "hcloud_ssh_key" "paperless_ssh_key" {
  name        = var.ssh_key_name
  public_key  = file(var.ssh_public_key_path)
  description = "SSH key for Paperless-NGX server access"
  
  labels = {
    environment = var.environment
    managed-by  = var.managed_by
    project     = var.project_name
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

# Network
resource "hcloud_network" "paperless_network" {
  name        = var.network_name
  ip_range    = var.network_ip_range
  description = "Private network for Paperless-NGX infrastructure"
  
  labels = {
    environment = var.environment
    managed-by  = var.managed_by
    project     = var.project_name
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

resource "hcloud_network_subnet" "paperless_subnet" {
  network_id   = hcloud_network.paperless_network.id
  type         = "cloud"
  network_zone = var.subnet_zone
  ip_range     = var.subnet_ip_range
  description  = "Subnet for Paperless-NGX server"
  
  labels = {
    environment = var.environment
    managed-by  = var.managed_by
    project     = var.project_name
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

# Server
resource "hcloud_server" "paperless" {
  name        = "paperless-ngx"
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.paperless_ssh_key.id]
  user_data   = templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
    admin_user     = var.paperless_admin_user
    admin_password = var.paperless_admin_password
    secret_key     = var.paperless_secret_key
    ocr_language   = var.paperless_ocr_language
    domain         = var.domain
    backup_enabled = var.backup_enabled
    backup_retention = var.backup_retention
    backup_cron    = var.backup_cron
    timezone       = var.timezone
    fail2ban_maxretry = var.fail2ban_maxretry
    fail2ban_bantime = var.fail2ban_bantime
    fail2ban_findtime = var.fail2ban_findtime
  })
  
  labels = {
    environment = var.environment
    managed-by  = var.managed_by
    project     = var.project_name
    role        = "paperless-server"
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = var.ignore_changes
  }

  depends_on = [
    hcloud_network_subnet.paperless_subnet,
    hcloud_volume.paperless_data
  ]
}

# Volume
resource "hcloud_volume" "paperless_data" {
  name        = "paperless-data"
  size        = var.volume_size
  server_id   = hcloud_server.paperless.id
  automount   = true
  format      = var.volume_format
  description = "Persistent storage for Paperless-NGX data"
  
  labels = {
    environment = var.environment
    managed-by  = var.managed_by
    project     = var.project_name
    purpose     = "paperless-storage"
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }

  depends_on = [
    hcloud_server.paperless
  ]
}

# Firewall
resource "hcloud_firewall" "paperless_firewall" {
  name        = "paperless-firewall"
  description = "Firewall rules for Paperless-NGX infrastructure"
  
  labels = {
    environment = var.environment
    managed-by  = var.managed_by
    project     = var.project_name
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = var.allowed_ssh_ips
    description = "SSH access from allowed IPs"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = var.allowed_http_ips
    description = "HTTP access"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = var.allowed_https_ips
    description = "HTTPS access"
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "any"
    destination_ips = ["0.0.0.0/0"]
    description = "Outbound TCP traffic"
  }

  rule {
    direction = "out"
    protocol  = "udp"
    port      = "any"
    destination_ips = ["0.0.0.0/0"]
    description = "Outbound UDP traffic"
  }

  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

resource "hcloud_firewall_attachment" "paperless_firewall_attachment" {
  firewall_id = hcloud_firewall.paperless_firewall.id
  server_ids  = [hcloud_server.paperless.id]
  
  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

# Wait for SSH to be available
resource "null_resource" "wait_for_ssh" {
  depends_on = [hcloud_server.paperless]

  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = hcloud_server.paperless.ipv4_address
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'SSH is now available'",
      "hostname",
      "uname -a"
    ]
  }
}

# Setup Paperless-NGX
resource "null_resource" "paperless_setup" {
  triggers = {
    always_run = timestamp()
  }
  
  depends_on = [
    null_resource.wait_for_ssh,
    hcloud_volume.paperless_data
  ]

  connection {
    type        = "ssh"
    user        = "root"
    host        = hcloud_server.paperless.ipv4_address
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
    agent       = false
  }

  # Copy the Docker compose file
  provisioner "file" {
    content = templatefile("${path.module}/templates/docker-compose.yml.tftpl", {
      admin_user     = var.paperless_admin_user
      admin_password = var.paperless_admin_password
      secret_key     = var.paperless_secret_key
      ocr_language   = var.paperless_ocr_language
      domain         = var.domain
      docker_compose_version = var.docker_compose_version
    })
    destination = "/root/docker-compose.yml"
  }

  # Copy HTTP-only Nginx config (used before certbot)
    provisioner "file" {
      content = templatefile("${path.module}/templates/nginx-http.conf.tftpl", {
        domain = var.domain
      })
      destination = "/root/nginx-http.conf"
    }

  # Copy the Nginx configuration
  provisioner "file" {
    content = templatefile("${path.module}/templates/nginx.conf.tftpl", {
      domain = var.domain
      ssl_email = var.ssl_email
      listen_port = var.listen_port
      proxy_pass_url = var.proxy_pass_url
      nginx_worker_processes = var.nginx_worker_processes
      nginx_worker_connections = var.nginx_worker_connections
    })
    destination = "/root/paperless-nginx.conf"
  }

  # Copy the backup script
  provisioner "file" {
    content = templatefile("${path.module}/templates/backup.sh.tftpl", {
      retention = var.backup_retention
      backup_encryption_key = var.backup_encryption_key
      backup_verify = var.backup_verify
      backup_test_frequency = var.backup_test_frequency
    })
    destination = "/root/backup.sh"
  }

  # Main setup script
  provisioner "remote-exec" {
    inline = [
      # Set error handling
      "set -e",
      "set -o pipefail",
      
      # Create log directory
      "mkdir -p /var/log/paperless-setup",
      
      # Update and install dependencies with error handling
      "apt-get update 2>&1 | tee -a /var/log/paperless-setup/install.log",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose fail2ban ufw python3-pip nginx-extras certbot python3-certbot-nginx 2>&1 | tee -a /var/log/paperless-setup/install.log",
      
      # Verify installations
      "command -v docker >/dev/null 2>&1 || { echo 'Docker installation failed' >&2; exit 1; }",
      "command -v docker-compose >/dev/null 2>&1 || { echo 'Docker Compose installation failed' >&2; exit 1; }",
      
      # Setup Docker with validation
      "systemctl enable docker 2>&1 | tee -a /var/log/paperless-setup/docker.log",
      "systemctl start docker 2>&1 | tee -a /var/log/paperless-setup/docker.log",
      "systemctl is-active --quiet docker || { echo 'Docker service failed to start' >&2; exit 1; }",

      # Volume safety checks
      "if [ ! -b /dev/sdb ]; then",
      "  echo 'Error: Volume /dev/sdb not found' >&2",
      "  exit 1",
      "fi",
      
      "if ! blkid /dev/sdb; then",
      "  echo 'Error: Volume /dev/sdb appears unformatted' >&2",
      "  exit 1",
      "fi",
      
      # Configure mount with validation
      "mkdir -p /opt/paperless-data",
      "grep -q '/dev/sdb' /etc/fstab || echo '/dev/sdb /opt/paperless-data ${var.volume_mount_options} 0 0' >> /etc/fstab",
      "mount -a 2>&1 | tee -a /var/log/paperless-setup/mount.log",
      "mount | grep -q '/opt/paperless-data' || { echo 'Volume mount failed' >&2; exit 1; }",

      # Setup directories with proper permissions
      "for dir in data media export consume config backup; do",
      "  mkdir -p /opt/paperless-data/$dir",
      "  chown -R 1000:1000 /opt/paperless-data/$dir",
      "  chmod 750 /opt/paperless-data/$dir",
      "done",
      
      # Verify directory permissions
      "find /opt/paperless-data -type d -not -perm 750 -ls | tee -a /var/log/paperless-setup/permissions.log",

      # Move configuration files
      "mv /root/docker-compose.yml /opt/paperless-ngx/",
      "mv /root/nginx-http.conf /etc/nginx/sites-available/paperless",
      "ln -sf /etc/nginx/sites-available/paperless /etc/nginx/sites-enabled/",
      "rm -f /etc/nginx/sites-enabled/default",

      # Configure Nginx and SSL if domain is provided
      "nginx -t 2>&1 | tee -a /var/log/paperless-setup/nginx.log",
      "if [ $? -ne 0 ]; then",
      "  echo 'Nginx configuration test failed' >&2",
      "  exit 1",
      "fi",
      
      "systemctl reload nginx 2>&1 | tee -a /var/log/paperless-setup/nginx.log",
      "systemctl is-active --quiet nginx || { echo 'Nginx service failed to start' >&2; exit 1; }",
      "MAX_RETRIES=3",
      "RETRY_DELAY=10",
      "for i in $(seq 1 $MAX_RETRIES); do",
      "  certbot --nginx -d ${var.domain} \\",
      "    --non-interactive --agree-tos \\",
      "    --email ${var.ssl_email} --redirect 2>&1 | tee -a /var/log/paperless-setup/ssl.log",
      "  if [ $? -eq 0 ]; then",
      "    break",
      "  fi",
      "  echo 'Certbot attempt $i failed. Retrying in $RETRY_DELAY seconds...'",
      "  sleep $RETRY_DELAY",
      "done",

      "echo 'Setting up certbot auto-renew cron job...'",
      "echo '0 3 * * 1 root certbot renew --quiet --no-self-upgrade' > /etc/cron.d/certbot-renew",

      "echo 'Configuring Fail2Ban for SSH protection...'",
      "cat > /etc/fail2ban/jail.d/ssh.conf << 'EOF'",
      "[sshd]",
      "enabled = true",
      "port    = ssh",
      "logpath = %(sshd_log)s",
      "backend = systemd",
      "maxretry = ${var.fail2ban_maxretry}",
      "bantime = ${var.fail2ban_bantime}",
      "findtime = ${var.fail2ban_findtime}",
      "EOF",
      
      "systemctl enable fail2ban 2>&1 | tee -a /var/log/paperless-setup/fail2ban.log",
      "systemctl restart fail2ban 2>&1 | tee -a /var/log/paperless-setup/fail2ban.log",
      "systemctl is-active --quiet fail2ban || { echo 'Fail2ban service failed to start' >&2; exit 1; }",
    
     "mv /root/paperless-nginx.conf /etc/nginx/sites-available/paperless",

      "cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak",
      "echo 'Ensuring limit_req_zone is defined in nginx.conf...'",
      <<-EOC
      cat <<'EOF' > /tmp/patch-nginx.sh
      #!/bin/bash

      set -e

      # Check if directive already exists
      if ! grep -q 'limit_req_zone $binary_remote_addr zone=mylimit' /etc/nginx/nginx.conf; then
        echo "Inserting rate limiting directive into nginx.conf..."
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
        sed -i '/http {/a \    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;' /etc/nginx/nginx.conf
      else
        echo "Rate limiting directive already exists."
      fi
      EOF

      chmod +x /tmp/patch-nginx.sh
      bash /tmp/patch-nginx.sh
      EOC
      ,
      "nginx -t && systemctl reload nginx",

      # Setup backup
      "mv /root/backup.sh /opt/paperless-ngx/backup.sh",
      "chmod +x /opt/paperless-ngx/backup.sh",
      
      # Configure backup cron job if enabled
      "if [ '${var.backup_enabled}' = 'true' ]; then",
      "  echo '${var.backup_cron} root /opt/paperless-ngx/backup.sh > /var/log/paperless-backup.log 2>&1' > /etc/cron.d/paperless-backup",
      "  chmod 644 /etc/cron.d/paperless-backup",
      "  /opt/paperless-ngx/backup.sh 2>&1 | tee -a /var/log/paperless-setup/backup.log",
      "fi",
      
      # Configure firewall with validation
      "ufw default deny incoming 2>&1 | tee -a /var/log/paperless-setup/firewall.log",
      "ufw default allow outgoing 2>&1 | tee -a /var/log/paperless-setup/firewall.log",
      "ufw allow ssh 2>&1 | tee -a /var/log/paperless-setup/firewall.log",
      "ufw allow http 2>&1 | tee -a /var/log/paperless-setup/firewall.log",
      "ufw allow https 2>&1 | tee -a /var/log/paperless-setup/firewall.log",
      "echo 'y' | ufw enable 2>&1 | tee -a /var/log/paperless-setup/firewall.log",
      "ufw status | grep -q 'Status: active' || { echo 'Firewall setup failed' >&2; exit 1; }",
      
      # Final validation
      "cd /opt/paperless-ngx",
      "docker-compose up -d 2>&1 | tee -a /var/log/paperless-setup/docker-compose.log",
      "sleep 30",  # Wait for containers to start
      "docker-compose ps | grep -q 'Up' || { echo 'Docker containers failed to start' >&2; exit 1; }",
      
      # Cleanup
      "rm -f /root/docker-compose.yml /root/nginx-http.conf /root/paperless-nginx.conf /root/backup.sh",
      
      # Final status check
      "echo 'Setup completed successfully at $(date)' >> /var/log/paperless-setup/setup.log"
    ]
  }
}