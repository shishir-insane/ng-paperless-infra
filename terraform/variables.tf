variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for server access"
  type        = string
}

variable "instance_name" {
  description = "Name of the server instance"
  type        = string
  default     = "paperless-ngx"
}

variable "instance_type" {
  description = "Hetzner Cloud server type"
  type        = string
  default     = "cx22"
}

variable "image" {
  description = "Hetzner Cloud server image"
  type        = string
  default     = "debian-12"
}

variable "location" {
  description = "Hetzner Cloud server location"
  type        = string
  default     = "nbg1"
}

variable "enable_user_data" {
  description = "Whether to enable user data script"
  type        = bool
  default     = false
}