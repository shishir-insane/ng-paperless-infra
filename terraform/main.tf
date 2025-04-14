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

# Check if the SSH key already exists
data "hcloud_ssh_key" "existing" {
  count = 1
  with_selector = "name=paperless-key"
}

# Only create a new key if it doesn't exist
resource "hcloud_ssh_key" "default" {
  count      = length(data.hcloud_ssh_key.existing) > 0 ? 0 : 1
  name       = "paperless-key"
  public_key = local.resolved_ssh_key
  lifecycle {
    prevent_destroy = false
    ignore_changes = [public_key] # Avoid errors if public key content changes
  }
}

# Use the existing key or the new one
locals {
  ssh_key_id = length(data.hcloud_ssh_key.existing) > 0 ? data.hcloud_ssh_key.existing[0].id : hcloud_ssh_key.default[0].id
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