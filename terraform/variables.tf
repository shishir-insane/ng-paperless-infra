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

# Provider Configuration
variable "provider_retry_max_retries" {
  description = "Maximum number of retries for provider operations"
  type        = number
  default     = 3
}

variable "provider_retry_min_delay" {
  description = "Minimum delay between retries in seconds"
  type        = number
  default     = 5
}

variable "provider_retry_max_delay" {
  description = "Maximum delay between retries in seconds"
  type        = number
  default     = 20
}

# Environment Configuration
variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "paperless-ngx"
}

variable "managed_by" {
  description = "Tool used to manage the infrastructure"
  type        = string
  default     = "terraform"
}

# Monitoring and Logging
variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "monitoring_enabled" {
  description = "Enable monitoring"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

# Security Configuration
variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to access SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_ips" {
  description = "List of IP addresses allowed to access HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_https_ips" {
  description = "List of IP addresses allowed to access HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "fail2ban_maxretry" {
  description = "Maximum number of failed login attempts before banning"
  type        = number
  default     = 5
}

variable "fail2ban_bantime" {
  description = "Duration of ban in seconds"
  type        = number
  default     = 3600
}

variable "fail2ban_findtime" {
  description = "Time window for counting failed attempts in seconds"
  type        = number
  default     = 3600
}

# Backup Configuration
variable "backup_encryption_key" {
  description = "Encryption key for backups"
  type        = string
  sensitive   = true
  default     = ""
}

variable "backup_verify" {
  description = "Enable backup verification"
  type        = bool
  default     = true
}

variable "backup_test_frequency" {
  description = "Frequency of backup testing (in days)"
  type        = number
  default     = 7
}

# Volume Configuration
variable "volume_format" {
  description = "Filesystem format for the volume"
  type        = string
  default     = "ext4"
}

variable "volume_mount_options" {
  description = "Mount options for the volume"
  type        = string
  default     = "defaults,nofail"
}

# Nginx Configuration
variable "nginx_worker_processes" {
  description = "Number of Nginx worker processes"
  type        = number
  default     = 4
}

variable "nginx_worker_connections" {
  description = "Number of connections per Nginx worker"
  type        = number
  default     = 1024
}

# Docker Configuration
variable "docker_compose_version" {
  description = "Version of Docker Compose to use"
  type        = string
  default     = "2.20.0"
}

# Resource Protection
variable "prevent_destroy" {
  description = "Prevent destruction of critical resources"
  type        = bool
  default     = true
}

variable "ignore_changes" {
  description = "List of attributes to ignore changes for"
  type        = list(string)
  default     = ["user_data"]
}

# System Configuration
variable "timezone" {
  description = "System timezone"
  type        = string
  default     = "UTC"
}