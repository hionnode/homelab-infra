#!/bin/bash

# Deploy GitHub Actions Runner from template

set -e

# Configuration
TEMPLATE_ID=999
GITHUB_TOKEN=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --id)
            CONTAINER_ID="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --token GITHUB_TOKEN --id CONTAINER_ID"
            echo "  --token: GitHub registration token"
            echo "  --id: Container ID for the new runner"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate inputs
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GitHub token is required (--token)"
    exit 1
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "Error: Container ID is required (--id)"
    exit 1
fi

echo "Deploying GitHub Actions runner..."

# Check if template exists
if ! pct status $TEMPLATE_ID >/dev/null 2>&1; then
    echo "Error: Template $TEMPLATE_ID not found. Run build.sh first."
    exit 1
fi

# Check if target container already exists
if pct status $CONTAINER_ID >/dev/null 2>&1; then
    echo "Error: Container $CONTAINER_ID already exists"
    exit 1
fi

# Clone the template
echo "Cloning template $TEMPLATE_ID to container $CONTAINER_ID..."
pct clone $TEMPLATE_ID $CONTAINER_ID --hostname "github-runner-$(date +%s)"

# Set up the GitHub token
echo "Setting up GitHub token..."
mkdir -p /var/lib/lxc/$CONTAINER_ID/rootfs/opt/actions-runner
echo "$GITHUB_TOKEN" > /var/lib/lxc/$CONTAINER_ID/rootfs/opt/actions-runner/token
chmod 600 /var/lib/lxc/$CONTAINER_ID/rootfs/opt/actions-runner/token

# Start the container
echo "Starting container $CONTAINER_ID..."
pct start $CONTAINER_ID

# Wait for it to be ready
echo "Waiting for runner to register..."
sleep 30

# Check status
if pct status $CONTAINER_ID | grep -q "running"; then
    echo "✅ Runner deployed successfully!"
    echo "Container ID: $CONTAINER_ID"
    echo "Check logs with: pct enter $CONTAINER_ID then journalctl -u github-runner -f"
else
    echo "❌ Failed to start container"
    exit 1
fi

# Show management commands
cat << EOF

Management commands:
- View logs: pct enter $CONTAINER_ID && journalctl -u github-runner -f
- Stop runner: pct stop $CONTAINER_ID
- Destroy runner: pct destroy $CONTAINER_ID
- Clone for more runners: pct clone $TEMPLATE_ID NEW_ID

EOF