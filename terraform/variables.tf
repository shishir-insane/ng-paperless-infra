# Hetzner Cloud API token
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

# Server configuration
variable "server_type" {
  description = "Server type to use (cx21, cx31, etc.)"
  type        = string
  default     = "cx21"
}

variable "location" {
  description = "Location for the server (nbg1, fsn1, hel1, etc.)"
  type        = string
  default     = "nbg1"
}

variable "image" {
  description = "OS image to use"
  type        = string
  default     = "ubuntu-22.04"
}

# Network configuration
variable "network_name" {
  description = "Name of the network"
  type        = string
  default     = "paperless-network"
}

variable "network_ip_range" {
  description = "IP range for the network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_ip_range" {
  description = "IP range for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_zone" {
  description = "Zone for the subnet"
  type        = string
  default     = "eu-central"
}

# SSH key configuration
variable "ssh_key_name" {
  description = "Name of the SSH key"
  type        = string
  default     = "paperless-ssh-key"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Volume configuration
variable "volume_size" {
  description = "Size of the volume in GB"
  type        = number
  default     = 10
}

# Volume cmount onfiguration
variable "paperless_mount_path" {
  type    = string
  default = "/opt/paperless-data"
}


# Paperless-NGX configuration
variable "paperless_admin_user" {
  description = "Admin username for Paperless-NGX"
  type        = string
  default     = "admin"
}

variable "paperless_admin_password" {
  description = "Admin password for Paperless-NGX"
  type        = string
  sensitive   = true
}

variable "paperless_secret_key" {
  description = "Secret key for Paperless-NGX"
  type        = string
  sensitive   = true
}

variable "paperless_ocr_language" {
  description = "Language for OCR"
  type        = string
  default     = "eng"
}

# Domain configuration
variable "domain" {
  description = "Domain name for Paperless-NGX"
  type        = string
  default     = ""
}

# SSL Email configuration
variable "ssl_email" {
  description = "Email to register with Let's Encrypt"
  type        = string
  default     = ""
}

variable "listen_port" {
  description = "The port nginx should listen on"
  type        = number
  default     = 80
}

variable "proxy_pass_url" {
  description = "The URL to proxy requests to"
  type        = string
  default     = "http://localhost:8000"
}

# Backup configuration
variable "backup_enabled" {
  description = "Enable backups"
  type        = bool
  default     = true
}

variable "backup_cron" {
  description = "Cron schedule for backups"
  type        = string
  default     = "0 2 * * *"
}

variable "backup_retention" {
  description = "Number of days to keep backups"
  type        = number
  default     = 7
}