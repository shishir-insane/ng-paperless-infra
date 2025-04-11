terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.42"  # Or latest version
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = "paperless-key"
  public_key = file(var.ssh_public_key_path)
}

resource "hcloud_server" "paperless" {
  name        = var.instance_name
  server_type = var.instance_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]

  labels = {
    project = "paperless"
  }
}