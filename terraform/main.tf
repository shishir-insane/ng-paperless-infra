terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.42"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

locals {
  resolved_ssh_key = var.ssh_public_key
}

# Get all SSH keys and find if our key exists by name
data "hcloud_ssh_keys" "all" {}

locals {
  existing_key = [
    for key in data.hcloud_ssh_keys.all.ssh_keys : key
    if key.name == "paperless-key"
  ]
  existing_key_found = length(local.existing_key) > 0
}

# Only create a new key if it doesn't exist
resource "hcloud_ssh_key" "default" {
  count      = local.existing_key_found ? 0 : 1
  name       = "paperless-key"
  public_key = local.resolved_ssh_key
  lifecycle {
    prevent_destroy = false
    ignore_changes = [public_key] # Avoid errors if public key content changes
  }
}

# Use the existing key or the new one
locals {
  ssh_key_id = local.existing_key_found ? local.existing_key[0].id : hcloud_ssh_key.default[0].id
}

resource "hcloud_server" "paperless" {
  name        = var.instance_name
  server_type = var.instance_type
  image       = var.image
  location    = var.location
  ssh_keys    = [local.ssh_key_id]
  user_data   = var.enable_user_data ? file("${path.module}/scripts/init.sh") : null
  labels = {
    project = "paperless"
  }
}