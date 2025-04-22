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

## Configuration Variables

### Provider Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `hcloud_token` | string | Hetzner Cloud API token | - |

### Environment Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `environment` | string | Environment name (e.g., production, staging, development) | "production" |
| `project_name` | string | Name of the project | "paperless-ngx" |
| `managed_by` | string | Tool used to manage the infrastructure | "terraform" |

### Server Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `server_type` | string | Server type to use (cx21, cx31, etc.) | "cx21" |
| `location` | string | Location for the server (nbg1, fsn1, hel1, etc.) | "nbg1" |
| `image` | string | OS image to use | "ubuntu-22.04" |

### Network Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `network_name` | string | Name of the network | "paperless-network" |
| `network_ip_range` | string | IP range for the network | "10.0.0.0/16" |
| `subnet_ip_range` | string | IP range for the subnet | "10.0.1.0/24" |
| `subnet_zone` | string | Zone for the subnet | "eu-central" |

### SSH Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `ssh_key_name` | string | Name of the SSH key | "paperless-ssh-key" |
| `ssh_public_key_path` | string | Path to the SSH public key file | "~/.ssh/id_rsa.pub" |
| `ssh_private_key_path` | string | Path to the SSH private key file | "~/.ssh/id_rsa" |

### Volume Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `volume_size` | number | Size of the volume in GB | 10 |
| `volume_format` | string | Filesystem format for the volume | "ext4" |
| `volume_mount_options` | string | Mount options for the volume | "defaults,nofail" |
| `paperless_mount_path` | string | Mount path for Paperless data | "/opt/paperless-data" |

### Security Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `allowed_ssh_ips` | list(string) | List of IP addresses allowed to access SSH | ["0.0.0.0/0"] |
| `allowed_http_ips` | list(string) | List of IP addresses allowed to access HTTP | ["0.0.0.0/0"] |
| `allowed_https_ips` | list(string) | List of IP addresses allowed to access HTTPS | ["0.0.0.0/0"] |
| `fail2ban_maxretry` | number | Maximum number of failed login attempts before banning | 5 |
| `fail2ban_bantime` | number | Duration of ban in seconds | 3600 |
| `fail2ban_findtime` | number | Time window for counting failed attempts in seconds | 3600 |

### Paperless-NGX Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `paperless_admin_user` | string | Admin username for Paperless-NGX | "admin" |
| `paperless_admin_password` | string | Admin password for Paperless-NGX | - |
| `paperless_secret_key` | string | Secret key for Paperless-NGX | - |
| `paperless_ocr_language` | string | Language for OCR | "eng" |

### Domain and SSL Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `domain` | string | Domain name for Paperless-NGX | "" |
| `ssl_email` | string | Email to register with Let's Encrypt | "" |
| `listen_port` | number | The port nginx should listen on | 80 |
| `proxy_pass_url` | string | The URL to proxy requests to | "http://localhost:8000" |

### Nginx Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `nginx_worker_processes` | number | Number of Nginx worker processes | 4 |
| `nginx_worker_connections` | number | Number of connections per Nginx worker | 1024 |

### Docker Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `docker_compose_version` | string | Version of Docker Compose to use | "2.20.0" |

### Backup Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `backup_enabled` | bool | Enable backups | true |
| `backup_cron` | string | Cron schedule for backups | "0 2 * * *" |
| `backup_retention` | number | Number of days to keep backups | 7 |
| `backup_encryption_key` | string | Encryption key for backups | "" |
| `backup_verify` | bool | Enable backup verification | true |
| `backup_test_frequency` | number | Frequency of backup testing (in days) | 7 |

### Monitoring and Logging
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `log_retention_days` | number | Number of days to retain logs | 30 |
| `monitoring_enabled` | bool | Enable monitoring | true |
| `alert_email` | string | Email address for alerts | "" |

### System Configuration
| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `timezone` | string | System timezone | "UTC" |

Note: Variables marked with `-` in the Default column are required and have no default value.


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
