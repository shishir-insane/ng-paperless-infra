variable "hcloud_token" {
  description = "Hetzner API token"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to your local public SSH key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "instance_name" {
  default     = "paperless-server"
  description = "Instance name"
}

variable "instance_type" {
  default     = "cx22" # 2GB RAM, 2 vCPU
  description = "Hetzner server type"
}

variable "image" {
  default     = "ubuntu-22.04"
  description = "OS image"
}

variable "location" {
  default     = "nbg1" # Nuremberg (Germany)
  description = "Server location"
}
