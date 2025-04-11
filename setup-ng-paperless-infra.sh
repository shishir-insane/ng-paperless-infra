#!/bin/bash

# Exit on error
set -e

echo "🔍 Checking for required tools..."

# Terraform
if ! command -v terraform &>/dev/null; then
  echo "📦 Installing Terraform..."
  brew tap hashicorp/tap
  brew install hashicorp/tap/terraform
else
  echo "✅ Terraform already installed."
fi

# AWS CLI
if ! command -v aws &>/dev/null; then
  echo "📦 Installing AWS CLI..."
  brew install awscli
else
  echo "✅ AWS CLI already installed."
fi

# Node.js + npm
if ! command -v node &>/dev/null; then
  echo "📦 Installing Node.js..."
  brew install node
else
  echo "✅ Node.js already installed."
fi

# Angular CLI
if ! command -v ng &>/dev/null; then
  echo "📦 Installing Angular CLI..."
  npm install -g @angular/cli
else
  echo "✅ Angular CLI already installed."
fi

echo ""
echo "🧾 AWS Credentials must be configured. If not done already, run:"
echo "    aws configure"
echo ""

# Ask for required Terraform inputs
read -p "🪣 Enter a globally unique S3 bucket name for ng-paperless: " BUCKET_NAME
read -p "🌍 Enter the CloudFront distribution ID (if available): " DIST_ID

# Store the input into a local tfvars file
cat <<EOF > local.auto.tfvars
bucket_name = "$BUCKET_NAME"
distribution_id = "$DIST_ID"
EOF

echo "🧹 Cleaning any previous Terraform state..."
rm -f terraform.tfstate* .terraform.lock.hcl

echo "🚀 Initializing Terraform..."
terraform init

echo "📐 Planning infrastructure..."
terraform plan

echo ""
read -p "⚠️ Proceed with apply? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Aborting..."
  exit 1
fi

echo "⏳ Applying infrastructure..."
terraform apply -auto-approve

echo ""
echo "✅ Infrastructure deployed successfully!"
echo "📋 Save the following credentials into GitHub → Settings → Secrets → Actions"
echo ""

# Fetch outputs for CI user credentials
AWS_KEY_ID=$(terraform output -raw ci_access_key_id)
AWS_SECRET_KEY=$(terraform output -raw ci_secret_access_key)

echo "🔑 AWS_ACCESS_KEY_ID: $AWS_KEY_ID"
echo "🔐 AWS_SECRET_ACCESS_KEY: $AWS_SECRET_KEY"
echo ""
echo "🪣 Bucket Name: $BUCKET_NAME"
echo "🌐 CloudFront Distribution ID: $DIST_ID"