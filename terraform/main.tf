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

# Use a fixed name for the SSH key
resource "hcloud_ssh_key" "default" {
  name       = "paperless-key"
  public_key = local.resolved_ssh_key
  lifecycle {
    prevent_destroy = false
    ignore_changes = [public_key] # Avoid errors if public key content changes
  }
}

resource "hcloud_server" "paperless" {
  name        = var.instance_name
  server_type = var.instance_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]
  user_data   = var.enable_user_data ? file("${path.module}/scripts/init.sh") : null

  labels = {
    project = "paperless"
  }
}