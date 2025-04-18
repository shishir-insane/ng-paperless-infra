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
  name       = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
}

# Network
resource "hcloud_network" "paperless_network" {
  name     = var.network_name
  ip_range = var.network_ip_range
}

resource "hcloud_network_subnet" "paperless_subnet" {
  network_id   = hcloud_network.paperless_network.id
  type         = "cloud"
  network_zone = var.subnet_zone
  ip_range     = var.subnet_ip_range
}

# Server
resource "hcloud_server" "paperless" {
  name        = "paperless-ngx"
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.paperless_ssh_key.id]

  network {
    network_id = hcloud_network.paperless_network.id
  }

  depends_on = [
    hcloud_network_subnet.paperless_subnet
  ]
}

# Volume
resource "hcloud_volume" "paperless_data" {
  name      = "paperless-data"
  size      = var.volume_size
  server_id = hcloud_server.paperless.id
  automount = true
  format    = "ext4"
}

# Firewall
resource "hcloud_firewall" "paperless_firewall" {
  name = "paperless-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "tcp"
    port      = "any"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "out"
    protocol  = "udp"
    port      = "any"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall_attachment" "paperless_firewall_attachment" {
  firewall_id = hcloud_firewall.paperless_firewall.id
  server_ids  = [hcloud_server.paperless.id]
}

# Wait for SSH to be available
resource "null_resource" "wait_for_ssh" {
  depends_on = [hcloud_server.paperless]

  connection {
    type        = "ssh"
    user        = "root"
    host        = hcloud_server.paperless.ipv4_address
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = ["echo 'SSH is now available'"]
  }
}

# Setup Paperless-NGX
resource "null_resource" "paperless_setup" {
  depends_on = [null_resource.wait_for_ssh, hcloud_volume.paperless_data]

  connection {
    type        = "ssh"
    user        = "root"
    host        = hcloud_server.paperless.ipv4_address
    private_key = file(var.ssh_private_key_path)
  }

  # Copy the Docker compose file
  provisioner "file" {
    content = templatefile("${path.module}/templates/docker-compose.yml.tftpl", {
      admin_user     = var.paperless_admin_user
      admin_password = var.paperless_admin_password
      secret_key     = var.paperless_secret_key
      ocr_language   = var.paperless_ocr_language
      domain         = var.domain
    })
    destination = "/root/docker-compose.yml"
  }

  # Copy the Nginx configuration
  provisioner "file" {
    content = templatefile("${path.module}/templates/nginx.conf.tftpl", {
      domain = var.domain
      ssl_email = var.ssl_email
    })
    destination = "/root/paperless-nginx.conf"
  }

  # Copy the backup script
  provisioner "file" {
    content = templatefile("${path.module}/templates/backup.sh.tftpl", {
      retention = var.backup_retention
    })
    destination = "/root/backup.sh"
  }

  # Main setup script
  provisioner "remote-exec" {
    inline = [
      # Update and install dependencies
      "apt-get update",
      "apt-get install -y docker.io docker-compose fail2ban ufw python3-pip nginx certbot python3-certbot-nginx",
      
      # Setup Docker
      "systemctl enable docker",
      "systemctl start docker",
      
      # Configure mount for the volume
      "mkdir -p /opt/paperless-ngx",
      "grep -q '/dev/sdb' /etc/fstab || echo '/dev/sdb /opt/paperless-ngx ext4 defaults 0 0' >> /etc/fstab",
      "mount -a",
      
      # Setup directories
      "mkdir -p /opt/paperless-ngx/{data,media,export,consume,config,backup}",
      "chown -R 1000:1000 /opt/paperless-ngx",
      
      # Move configuration files
      "mv /root/docker-compose.yml /opt/paperless-ngx/",
      "mv /root/paperless-nginx.conf /etc/nginx/sites-available/paperless",
      "ln -sf /etc/nginx/sites-available/paperless /etc/nginx/sites-enabled/",
      "rm -f /etc/nginx/sites-enabled/default",
      
      # Configure Nginx and SSL if domain is provided
      "nginx -t && systemctl reload nginx",
      "for i in {1..10}; do curl -s --head http://localhost | grep '200 OK' && break || sleep 10; done",
      <<-EOC
        for i in {1..3}; do
          certbot --nginx -d ${var.domain} \
            --non-interactive --agree-tos \
            --email ${var.ssl_email} --redirect && break
          echo 'Certbot failed. Retrying in 10s...'
          sleep 10
        done
      EOC
      ,
      "echo 'Setting up certbot auto-renew cron job...'",
      "echo '0 3 * * 1 root certbot renew --quiet --no-self-upgrade' > /etc/cron.d/certbot-renew",

      "echo 'Configuring Fail2Ban for SSH protection...'",
      <<-EOC
      cat <<'EOF' > /etc/fail2ban/jail.d/ssh.conf
      [sshd]
      enabled = true
      port    = ssh
      logpath = %(sshd_log)s
      backend = systemd
      maxretry = 5
      bantime = 1h
      EOF
      EOC
      ,

      "systemctl enable fail2ban",
      "systemctl restart fail2ban"

      # Setup backup
      "mv /root/backup.sh /opt/paperless-ngx/backup.sh",
      "chmod +x /opt/paperless-ngx/backup.sh",
      
      # Configure backup cron job if enabled
      "${var.backup_enabled ? "echo \"${var.backup_cron} root /opt/paperless-ngx/backup.sh > /var/log/paperless-backup.log 2>&1\" > /etc/cron.d/paperless-backup" : "echo 'Backup not enabled, skipping cron setup'"}",
      
      # Configure firewall
      "ufw default deny incoming",
      "ufw default allow outgoing",
      "ufw allow ssh",
      "ufw allow http",
      "ufw allow https",
      "echo 'y' | ufw enable",
      
      # Start Paperless-NGX
      "cd /opt/paperless-ngx && docker-compose up -d"
    ]
  }
}