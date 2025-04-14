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
  description = "The name of the created SSH key"
  value       = length(hcloud_ssh_key.default) > 0 ? hcloud_ssh_key.default[0].name : "Using existing key: paperless-key"
}