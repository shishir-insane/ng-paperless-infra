#!/bin/bash

# Step 1: Find the ID of the existing SSH key in Hetzner Cloud
echo "Finding existing SSH keys in Hetzner Cloud..."
hcloud ssh-key list

# Step 2: Import the existing SSH key into Terraform state
# Replace <SSH_KEY_ID> with the actual ID from the output above
echo "Import the SSH key using:"
echo "terraform import hcloud_ssh_key.paperless_ssh_key <SSH_KEY_ID>"

# Step 3: Verify the import was successful
echo "Verify the import with:"
echo "terraform state show hcloud_ssh_key.paperless_ssh_key"

# Step 4: Run terraform plan to ensure no changes are needed
echo "Then run terraform plan to verify configuration matches:"
echo "terraform plan"