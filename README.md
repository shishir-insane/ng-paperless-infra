# Paperless-ng Deployment on Hetzner Cloud

## Requirements

- Hetzner API Token
- Terraform CLI
- SSH public key

## Usage

```bash
terraform init
terraform apply -var="hcloud_token=your_token_here"
