#!/bin/bash

# Build script for GitHub Actions Runner LXC template

set -e

# Configuration
PROXMOX_HOST="your-proxmox-host.local"
PROXMOX_USER="root@pam"
GITHUB_REPO="https://github.com/YOUR_ORG/YOUR_REPO"
TEMPLATE_NAME="github-runner-template"

# Prompt for sensitive information
read -sp "Proxmox password: " PROXMOX_PASSWORD
echo
read -p "GitHub repository URL [$GITHUB_REPO]: " REPO_INPUT
GITHUB_REPO=${REPO_INPUT:-$GITHUB_REPO}

echo "Building GitHub Actions Runner template..."

# Initialize packer plugins
packer init .

# Validate the template
echo "Validating Packer template..."
packer validate \
    -var "proxmox_url=https://${PROXMOX_HOST}:8006/api2/json" \
    -var "proxmox_username=${PROXMOX_USER}" \
    -var "proxmox_password=${PROXMOX_PASSWORD}" \
    -var "github_repo_url=${GITHUB_REPO}" \
    github-runner.pkr.hcl

# Build the template
echo "Building template..."
packer build \
    -var "proxmox_url=https://${PROXMOX_HOST}:8006/api2/json" \
    -var "proxmox_username=${PROXMOX_USER}" \
    -var "proxmox_password=${PROXMOX_PASSWORD}" \
    -var "github_repo_url=${GITHUB_REPO}" \
    github-runner.pkr.hcl

echo "Template build complete!"
echo "You can now create containers from this template and deploy them on-demand."

# Show next steps
cat << EOF

Next steps:
1. Create containers from the template:
   pct clone 999 200 --hostname github-runner-01

2. Set the GitHub token before starting:
   echo "YOUR_GITHUB_TOKEN" > /var/lib/lxc/200/rootfs/opt/actions-runner/token

3. Start the container:
   pct start 200

4. The runner will automatically register and start working!

EOF