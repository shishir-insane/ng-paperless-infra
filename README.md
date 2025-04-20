# Paperless-NGX Infrastructure on Hetzner Cloud

This Terraform project sets up [Paperless-NGX](https://docs.paperless-ngx.com/) on a Hetzner Cloud server. Paperless-NGX is a document management system that allows you to scan, index, and archive your physical documents.

## Architecture Overview

The infrastructure consists of the following components:

- **Hetzner Cloud Server**: A virtual machine running Ubuntu
- **Persistent Storage**: A Hetzner Cloud Volume for storing documents and database
- **Docker Containers**:
  - Paperless-NGX web application
  - PostgreSQL database
  - Redis message broker
- **Nginx**: Reverse proxy with SSL termination
- **Backup System**: Automated daily backups of database and configuration

## Features

- **Automated Deployment**: One-click deployment using Terraform
- **High Availability**: Persistent storage ensures data safety
- **Security**:
  - Automatic HTTPS with Let's Encrypt
  - Firewall rules for network security
  - Fail2ban for SSH protection
- **Backup & Recovery**:
  - Daily automated backups
  - Configurable retention period
  - Database and configuration backups
- **Monitoring**: Basic system monitoring and logging
- **Document Processing**:
  - OCR (Optical Character Recognition)
  - Automatic document classification
  - Tagging and search capabilities

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- [Hetzner Cloud](https://www.hetzner.com/cloud) account
- SSH key pair
- Domain name (optional, but recommended for HTTPS)

## Project Structure

```
terraform/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf             # Output definitions
├── terraform.tfvars       # Your specific variables (not in git)
├── terraform.tfvars.example  # Example variables file
├── .terraform.lock.hcl    # Dependency lock file
└── templates/             # Template files for configuration
    ├── docker-compose.yml.tftpl
    ├── nginx-http.conf.tftpl
    ├── nginx.conf.tftpl
    ├── backup.sh.tftpl
    └── cloud-init.yml.tftpl
```

## Getting Started

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/ng-paperless-infra.git
   cd ng-paperless-infra
   ```

2. **Configure Variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values:
   - `hcloud_token`: Your Hetzner Cloud API token
   - `ssh_public_key_path`: Path to your public SSH key
   - `ssh_private_key_path`: Path to your private SSH key
   - `paperless_admin_user`: Admin username for Paperless-NGX
   - `paperless_admin_password`: Strong admin password
   - `paperless_secret_key`: Random secret key for Django
   - `domain`: Your domain name (optional)
   - `ssl_email`: Email for Let's Encrypt notifications
   - `backup_retention`: Number of days to keep backups

3. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

4. **Review the Plan**:
   ```bash
   terraform plan
   ```

5. **Apply the Configuration**:
   ```bash
   terraform apply
   ```

6. **Access Paperless-NGX**:
   - If you provided a domain: `https://your-domain.com`
   - Without domain: `http://server-ip:8000`

## Configuration Options

### Server Configuration
- `server_type`: Size of the server (default: cx21)
- `volume_size`: Storage volume size in GB (default: 50)
- `location`: Hetzner Cloud location (default: nbg1)

### Paperless-NGX Settings
- `paperless_ocr_language`: Language for OCR processing
- `paperless_time_zone`: Server timezone
- `paperless_url`: Base URL for the application

### Backup Configuration
- `backup_enabled`: Enable/disable automated backups
- `backup_retention`: Number of days to keep backups
- `backup_cron`: Cron schedule for backups (default: daily at 2 AM)

## Security Considerations

1. **Network Security**:
   - Only necessary ports are open (22, 80, 443)
   - UFW firewall is configured
   - Fail2ban protects against brute force attacks

2. **Application Security**:
   - HTTPS enforced when domain is provided
   - Strong admin password required
   - Regular security updates

3. **Data Protection**:
   - Persistent storage for data safety
   - Regular automated backups
   - Database encryption

## Maintenance

### Updating Paperless-NGX
```bash
ssh root@your-server-ip
cd /opt/paperless-ngx
docker-compose pull
docker-compose up -d
```

### Checking Logs
```bash
ssh root@your-server-ip
cd /opt/paperless-ngx
docker-compose logs -f
```

### Backup Management
- Backups are stored in `/opt/paperless-ngx/backup`
- Daily backups include:
  - PostgreSQL database dump
  - Configuration files
  - Docker Compose configuration

## Troubleshooting

1. **Server Access Issues**:
   ```bash
   ssh root@your-server-ip
   systemctl status nginx
   systemctl status docker
   ```

2. **Application Issues**:
   ```bash
   cd /opt/paperless-ngx
   docker-compose ps
   docker-compose logs
   ```

3. **Storage Issues**:
   ```bash
   df -h
   ls -la /opt/paperless-ngx
   ```

4. **Backup Issues**:
   ```bash
   cat /var/log/paperless-backup.log
   ls -la /opt/paperless-ngx/backup
   ```

## License

[Apache License 2.0](LICENSE)
