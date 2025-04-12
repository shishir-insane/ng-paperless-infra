# Paperless-ng Deployment on Hetzner Cloud

[![Deploy Paperless to Hetzner](https://github.com/shishir-insane/ng-paperless-infra/actions/workflows/deploy.yml/badge.svg)](https://github.com/shishir-insane/ng-paperless-infra/actions/workflows/deploy.yml)

## Requirements

- Hetzner API Token
- Terraform CLI
- SSH public key

## Usage

```bash
terraform init
terraform apply -var="hcloud_token=your_token_here"
