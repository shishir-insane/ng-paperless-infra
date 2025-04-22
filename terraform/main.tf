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
}

# SSH Key
resource "hcloud_ssh_key" "paperless_ssh_key" {
  name        = var.ssh_key_name
  public_key  = file(var.ssh_public_key_path)
  
  labels = {
    environment = var.environment
    managed-by  = var.managed_by
    project     = var.project_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Network
resource "hcloud_network" "paperless_network" {
  name        = var.network_name
  ip_range    = var.network_ip_range
  
  labels = {
    environment = var.environment
    managed-by  = var.managed_by
    project     = var.project_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_network_subnet" "paperless_subnet" {
  network_id   = hcloud_network.paperless_network.id
  type         = "cloud"
  network_zone = var.subnet_zone
  ip_range     = var.subnet_ip_range

  lifecycle {
    prevent_destroy = true
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
    prevent_destroy = true
    ignore_changes = [user_data]
  }

  depends_on = [
    hcloud_network_subnet.paperless_subnet
  ]
}

# Volume
resource "hcloud_volume" "paperless_data" {
  name        = "paperless-data"
  size        = var.volume_size
  server_id   = hcloud_server.paperless.id
  automount   = true
  format      = var.volume_format
  
  labels = {
    environment = var.environment
    managed-by  = var.managed_by
    project     = var.project_name
    purpose     = "paperless-storage"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    hcloud_server.paperless
  ]
}

# Firewall
resource "hcloud_firewall" "paperless_firewall" {
  name        = "paperless-firewall"
  
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
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = var.allowed_http_ips
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = var.allowed_https_ips
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "any"
    destination_ips = ["0.0.0.0/0"]
  }

  rule {
    direction = "out"
    protocol  = "udp"
    port      = "any"
    destination_ips = ["0.0.0.0/0"]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_firewall_attachment" "paperless_firewall_attachment" {
  firewall_id = hcloud_firewall.paperless_firewall.id
  server_ids  = [hcloud_server.paperless.id]
  
  lifecycle {
    prevent_destroy = true
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
      # Set error handling and debugging
      "set -x",  # Enable debugging output
      "exec 2>&1",  # Redirect stderr to stdout
      
      # Create log directory
      "echo 'Creating log directory...'",
      "mkdir -p /var/log/paperless-setup",
      
      # Update and install dependencies with error handling
      "echo 'Updating package lists...'",
      "apt-get update > /var/log/paperless-setup/install.log 2>&1 || { echo 'apt-get update failed'; exit 1; }",
      
      "echo 'Installing system dependencies...'",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip ufw fail2ban >> /var/log/paperless-setup/install.log 2>&1 || { echo 'System package installation failed'; exit 1; }",
      
      "echo 'Installing Docker...'",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io >> /var/log/paperless-setup/install.log 2>&1 || { echo 'Docker installation failed'; exit 1; }",
      
      "echo 'Installing Docker Compose...'",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y docker-compose >> /var/log/paperless-setup/install.log 2>&1 || { echo 'Docker Compose installation failed'; exit 1; }",
      
      "echo 'Installing Nginx and Certbot...'",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y nginx-extras certbot python3-certbot-nginx >> /var/log/paperless-setup/install.log 2>&1 || { echo 'Nginx/Certbot installation failed'; exit 1; }",
      
      # Verify installations
      "echo 'Verifying installations...'",
      "command -v docker >/dev/null 2>&1 || { echo 'Docker installation failed' >&2; exit 1; }",
      "command -v docker-compose >/dev/null 2>&1 || { echo 'Docker Compose installation failed' >&2; exit 1; }",
      
      # Setup Docker with validation
      "echo 'Setting up Docker...'",
      "systemctl enable docker > /var/log/paperless-setup/docker.log 2>&1 || { echo 'Docker enable failed' >&2; exit 1; }",
      "systemctl start docker >> /var/log/paperless-setup/docker.log 2>&1 || { echo 'Docker start failed' >&2; exit 1; }",
      "systemctl is-active --quiet docker || { echo 'Docker service failed to start' >&2; exit 1; }",

      # Volume safety checks
      "echo 'Checking volume /dev/sdb...'",
      "if [ ! -b /dev/sdb ]; then",
      "  echo 'Error: Volume /dev/sdb not found' >&2",
      "  ls -la /dev/sd* >&2",
      "  exit 1",
      "fi",
      
      "echo 'Checking volume format...'",
      "if ! blkid /dev/sdb; then",
      "  echo 'Error: Volume /dev/sdb appears unformatted' >&2",
      "  exit 1",
      "fi",
      
      # Configure mount with validation
      "echo 'Setting up mount point...'",
      "mkdir -p ${var.paperless_mount_path}",
      "chmod 755 ${var.paperless_mount_path}",
      
      "echo 'Checking for existing mounts...'",
      "if mount | grep -q '/dev/sdb'; then",
      "  echo 'Volume is already mounted, unmounting first...'",
      "  umount /dev/sdb || { echo 'Failed to unmount existing volume' >&2; exit 1; }",
      "fi",
      
      "echo 'Removing duplicate fstab entries...'",
      "sed -i '/\\/dev\\/sdb/d' /etc/fstab",
      
      "echo 'Adding to fstab...'",
      "echo '/dev/sdb ${var.paperless_mount_path} ${var.volume_format} ${var.volume_mount_options} 0 0' >> /etc/fstab",
      
      "echo 'Mounting volume...'",
      "mount -a > /var/log/paperless-setup/mount.log 2>&1",
      
      "echo 'Verifying mount...'",
      "if ! mount | grep -q '${var.paperless_mount_path}'; then",
      "  echo 'Volume mount failed. Checking mount log:' >&2",
      "  cat /var/log/paperless-setup/mount.log >&2",
      "  echo 'Current mounts:' >&2",
      "  mount >&2",
      "  echo 'fstab contents:' >&2",
      "  cat /etc/fstab >&2",
      "  exit 1",
      "fi",
      
      "echo 'Setting volume permissions...'",
      "chown -R root:root ${var.paperless_mount_path}",
      "chmod 755 ${var.paperless_mount_path}",

      # Setup directories with proper permissions
      "echo 'Creating data directories...'",
      "for dir in data media export import consume config backup; do",
      "  mkdir -p ${var.paperless_mount_path}/$dir",
      "  chown -R 1000:1000 ${var.paperless_mount_path}/$dir",
      "  chmod 750 ${var.paperless_mount_path}/$dir",
      "done",
      
      # Verify directory permissions
      "echo 'Verifying directory permissions...'",
      "find ${var.paperless_mount_path} -type d -not -perm 750 -ls > /var/log/paperless-setup/permissions.log",

      # Move configuration files
      "echo 'Moving configuration files...'",
      "mkdir -p /opt/paperless-ngx",
      "mv /root/docker-compose.yml /opt/paperless-ngx/ || { echo 'Failed to move docker-compose.yml' >&2; exit 1; }",
      "mv /root/nginx-http.conf /etc/nginx/sites-available/paperless || { echo 'Failed to move nginx-http.conf' >&2; exit 1; }",
      "ln -sf /etc/nginx/sites-available/paperless /etc/nginx/sites-enabled/ || { echo 'Failed to create nginx symlink' >&2; exit 1; }",
      "rm -f /etc/nginx/sites-enabled/default",

      # Configure Nginx and SSL if domain is provided
      "echo 'Configuring Nginx...'",
      "nginx -t > /var/log/paperless-setup/nginx.log 2>&1 || { echo 'Nginx configuration test failed' >&2; exit 1; }",
      
      "systemctl reload nginx >> /var/log/paperless-setup/nginx.log 2>&1 || { echo 'Nginx reload failed' >&2; exit 1; }",
      "systemctl is-active --quiet nginx || { echo 'Nginx service failed to start' >&2; exit 1; }",

      # Configure SSL if domain is provided
      "if [ -n '${var.domain}' ]; then",
      "  echo 'Configuring SSL...'",
      "  MAX_RETRIES=3",
      "  RETRY_DELAY=10",
      "  for i in $(seq 1 $MAX_RETRIES); do",
      "    certbot --nginx -d ${var.domain} \\",
      "      --non-interactive --agree-tos \\",
      "      --email ${var.ssl_email} --redirect > /var/log/paperless-setup/ssl.log 2>&1",
      "    if [ $? -eq 0 ]; then",
      "      break",
      "    fi",
      "    echo 'Certbot attempt $i failed. Retrying in $RETRY_DELAY seconds...'",
      "    sleep $RETRY_DELAY",
      "  done",
      "fi",

      "echo 'Setting up certbot auto-renew cron job...'",
      "echo '0 3 * * 1 root certbot renew --quiet --no-self-upgrade' > /etc/cron.d/certbot-renew",

      # Configure Fail2Ban
      "echo 'Configuring Fail2Ban...'",
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
      
      "systemctl enable fail2ban > /var/log/paperless-setup/fail2ban.log 2>&1 || { echo 'Fail2ban enable failed' >&2; exit 1; }",
      "systemctl restart fail2ban >> /var/log/paperless-setup/fail2ban.log 2>&1 || { echo 'Fail2ban restart failed' >&2; exit 1; }",
      "systemctl is-active --quiet fail2ban || { echo 'Fail2ban service failed to start' >&2; exit 1; }",
    
      # Configure Nginx rate limiting
      "echo 'Configuring Nginx rate limiting...'",
      "mv /root/paperless-nginx.conf /etc/nginx/sites-available/paperless || { echo 'Failed to move nginx config' >&2; exit 1; }",

      "cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak",
      "cat <<'EOF' > /tmp/patch-nginx.sh",
      "#!/bin/bash",
      "set -e",
      "if ! grep -q 'limit_req_zone $binary_remote_addr zone=mylimit' /etc/nginx/nginx.conf; then",
      "  echo 'Inserting rate limiting directive into nginx.conf...'",
      "  cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak",
      "  sed -i '/http {/a\\'$'\\n''    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;' /etc/nginx/nginx.conf",
      "else",
      "  echo 'Rate limiting directive already exists.'",
      "fi",
      "EOF",

      "chmod +x /tmp/patch-nginx.sh",
      "/tmp/patch-nginx.sh",
      "nginx -t && systemctl reload nginx || { echo 'Nginx configuration failed' >&2; exit 1; }",

      # Setup backup
      "echo 'Setting up backup...'",
      "mv /root/backup.sh /opt/paperless-ngx/backup.sh || { echo 'Failed to move backup script' >&2; exit 1; }",
      "chmod +x /opt/paperless-ngx/backup.sh",
      
      # Configure backup cron job if enabled
      "if [ '${var.backup_enabled}' = 'true' ]; then",
      "  echo 'Configuring backup cron job...'",
      "  echo '${var.backup_cron} root /opt/paperless-ngx/backup.sh > /var/log/paperless-backup.log 2>&1' > /etc/cron.d/paperless-backup",
      "  chmod 644 /etc/cron.d/paperless-backup",
      "  /opt/paperless-ngx/backup.sh > /var/log/paperless-setup/backup.log 2>&1 || { echo 'Initial backup failed' >&2; exit 1; }",
      "fi",
      
      # Configure firewall
      "echo 'Configuring firewall...'",
      "ufw default deny incoming > /var/log/paperless-setup/firewall.log 2>&1 || { echo 'Firewall configuration failed' >&2; exit 1; }",
      "ufw default allow outgoing >> /var/log/paperless-setup/firewall.log 2>&1",
      "ufw allow ssh >> /var/log/paperless-setup/firewall.log 2>&1",
      "ufw allow http >> /var/log/paperless-setup/firewall.log 2>&1",
      "ufw allow https >> /var/log/paperless-setup/firewall.log 2>&1",
      "echo 'y' | ufw enable >> /var/log/paperless-setup/firewall.log 2>&1 || { echo 'Firewall enable failed' >&2; exit 1; }",
      "ufw status | grep -q 'Status: active' || { echo 'Firewall setup failed' >&2; exit 1; }",
      
      # Final validation
      "echo 'Starting Paperless-NGX...'",
      "cd /opt/paperless-ngx",
      "docker-compose up -d > /var/log/paperless-setup/docker-compose.log 2>&1 || { echo 'Docker Compose up failed' >&2; exit 1; }",
      "sleep 30",  # Wait for containers to start
      "docker-compose ps | grep -q 'Up' || { echo 'Docker containers failed to start' >&2; exit 1; }",
      
      # Cleanup
      "echo 'Cleaning up...'",
      "rm -f /root/docker-compose.yml /root/nginx-http.conf /root/paperless-nginx.conf /root/backup.sh",
      
      # Final status check
      "echo 'Setup completed successfully at $(date)' >> /var/log/paperless-setup/setup.log",
      "echo 'Setup completed successfully'"
    ]
  }
}