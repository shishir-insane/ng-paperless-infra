terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.50.0"  # Updated to match your locked version
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
}

resource "hcloud_firewall_attachment" "paperless_firewall_attachment" {
  firewall_id = hcloud_firewall.paperless_firewall.id
  server_ids  = [hcloud_server.paperless.id]
}

# Output the server IP
output "server_ipv4" {
  value = hcloud_server.paperless.ipv4_address
}

output "ssh_key_name" {
  value = hcloud_ssh_key.paperless_ssh_key.name
}