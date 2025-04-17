output "instance_ip" {
  description = "Public IP of the Hetzner server"
  value       = hcloud_server.paperless.ipv4_address
}

output "instance_name" {
  description = "Name of the Hetzner server instance"
  value       = hcloud_server.paperless.name
}

output "instance_labels" {
  description = "Labels applied to the server"
  value       = hcloud_server.paperless.labels
}

output "ssh_key_name" {
  description = "SSH key name of the server"
  value = hcloud_ssh_key.paperless_ssh_key.name
}