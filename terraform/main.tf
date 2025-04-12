terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.42"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "random_id" "unique_id" {
  byte_length = 2
}

locals {
  resolved_ssh_key = var.ssh_public_key
}

resource "hcloud_ssh_key" "default" {
  name       = "paperless-key-${random_id.unique_id.hex}"
  public_key = local.resolved_ssh_key
  lifecycle {
    prevent_destroy = false
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