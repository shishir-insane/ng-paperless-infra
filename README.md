# Paperless-NGX Infrastructure on Hetzner Cloud

This Terraform project sets up [Paperless-NGX](https://docs.paperless-ngx.com/) on a Hetzner Cloud server.

[![Deploy Paperless to Hetzner](https://github.com/shishir-insane/ng-paperless-infra/actions/workflows/deploy.yml/badge.svg)](https://github.com/shishir-insane/ng-paperless-infra/actions/workflows/deploy.yml)

## Features

- Automated setup of Paperless-NGX using Docker Compose
- Persistent storage with Hetzner Cloud Volumes
- Automatic HTTPS with Let's Encrypt (if domain is provided)
- Scheduled backups of database and configuration
- Secured with firewall rules

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- [Hetzner Cloud](https://www.hetzner.com/cloud) account
- SSH key pair

## Getting Started

1. Clone this repository:
   ```
   git clone https://github.com/your-username/ng-paperless-infra.git
   cd ng-paperless-infra
   ```

2. Create a terraform.tfvars file based on the example:
   ```
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit terraform.tfvars with your specific values:
   - Add your Hetzner Cloud API token
   - Configure your SSH key paths
   - Set a strong admin password and secret key
   - Configure your domain (optional)

4. Initialize Terraform:
   ```
   terraform init
   ```

5. Apply the configuration:
   ```
   terraform apply
   ```

6. After deployment completes, access Paperless-NGX at the URL provided in the output.

## Configuration

The main configuration options are:

- `server_type`: Size of the server (cx21 is recommended minimum)
- `volume_size`: Size of the persistent storage volume in GB
- `paperless_ocr_language`: Language for OCR processing
- `domain`: Your domain name (optional)
- `backup_enabled`: Enable automated backups
- `backup_retention`: Number of days to keep backups

See variables.tf for all available options.

## Backups

Backups are enabled by default and run daily at 2 AM. They include:
- PostgreSQL database dumps
- Docker Compose configuration
- Custom configuration files

You can configure backup settings in terraform.tfvars.

## Security

- SSH access is secured with key-based authentication
- Firewall is configured to allow only necessary ports (SSH, HTTP, HTTPS)
- HTTPS is automatically configured when a domain is provided

## Troubleshooting

If you encounter issues:

1. Check the server status:
   ```
   ssh root@<server_ip>
   ```

2. View Docker container logs:
   ```
   cd /opt/paperless-ngx
   docker-compose logs
   ```

3. Verify the volume is properly mounted:
   ```
   df -h | grep paperless
   ```

## License

[MIT](LICENSE)
