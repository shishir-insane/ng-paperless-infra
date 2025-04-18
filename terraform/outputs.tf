output "server_ipv4" {
  description = "The IPv4 address of the server"
  value       = hcloud_server.paperless.ipv4_address
}

output "server_status" {
  description = "The status of the server"
  value       = hcloud_server.paperless.status
}

output "paperless_url" {
  description = "URL to access Paperless-NGX"
  value       = var.domain != "" ? "https://${var.domain}" : "http://${hcloud_server.paperless.ipv4_address}"
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${hcloud_server.paperless.ipv4_address}"
}

output "ssh_key_name" {
  description = "Name of the SSH key used"
  value       = hcloud_ssh_key.paperless_ssh_key.name
}

output "ssh_key_id" {
  description = "ID of the SSH key used"
  value = data.hcloud_ssh_key.paperless_ssh_key.id
}