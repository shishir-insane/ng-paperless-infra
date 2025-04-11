output "instance_ip" {
  description = "Public IP of Hetzner instance"
  value       = hcloud_server.paperless.ipv4_address
}

output "instance_name" {
  description = "Hetzner instance name"
  value       = hcloud_server.paperless.name
}