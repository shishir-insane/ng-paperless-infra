variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Raw SSH public key string (used in CI/CD)"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/hetzner-paperless.pub"
  description = "Path to SSH public key file for local use"
}

variable "instance_name" {
  type        = string
  default     = "paperless-server"
}

variable "instance_type" {
  type        = string
  default     = "cx22"
}

variable "image" {
  type        = string
  default     = "ubuntu-22.04"
}

variable "location" {
  type        = string
  default     = "nbg1"
}

variable "enable_user_data" {
  type        = bool
  default     = false
}
