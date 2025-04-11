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

# SSH key from raw value or from file (one should be provided)
locals {
  resolved_ssh_key = var.ssh_public_key != "" ? var.ssh_public_key : file(var.ssh_public_key_path)
}

resource "hcloud_ssh_key" "default" {
  name       = "paperless-key"
  public_key = local.resolved_ssh_key
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