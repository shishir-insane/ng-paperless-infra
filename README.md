# ng-paperless Infrastructure (Terraform)

This project sets up the infrastructure for hosting the **ng-paperless** Angular frontend using **AWS S3 + CloudFront** via Terraform.

## Features

- S3 bucket for static hosting
- Public read policy for the frontend
- CloudFront distribution with SPA routing support
- Automatic 403/404 fallback to `index.html`
- Easily extensible for ACM and custom domains

## Requirements

- Terraform >= 1.0
- AWS CLI (configured)
- Angular project build in `dist/ng-paperless/`

## Usage

```bash
# Clone the repo
git clone https://github.com/your-org/ng-paperless-infra.git
cd ng-paperless-infra

# Initialize Terraform
terraform init

# Preview changes
terraform plan -var="bucket_name=your-ng-paperless-site"

# Apply the infrastructure
terraform apply -var="bucket_name=your-ng-paperless-site"
```

## CI/CD with GitHub Actions

Every push to `main` will:
- Build the Angular frontend
- Upload the contents to S3
- Invalidate CloudFront to reflect latest changes

Make sure to set the required secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
