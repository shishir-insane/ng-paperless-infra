# Public IPv4 address of the server
output "instance_ip" {
  description = "Public IP of the Hetzner server"
  value       = hcloud_server.paperless.ipv4_address
}

# Hostname of the server (same as instance name)
output "instance_name" {
  description = "Name of the Hetzner server instance"
  value       = hcloud_server.paperless.name
}

# Full server label output (optional, useful for debugging or tagging)
output "instance_labels" {
  description = "Labels applied to the server"
  value       = hcloud_server.paperless.labels
}

output "ssh_key_name" {
  description = "The name of the created SSH key"
  value       = hcloud_ssh_key.default.name
}