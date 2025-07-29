#!/bin/bash

# Configuration
GITHUB_URL="${github_repo_url}"
RUNNER_NAME="proxmox-runner-$(hostname)-$(date +%s)"

# Get registration token from environment or file
if [ -f /opt/actions-runner/token ]; then
    RUNNER_TOKEN=$(cat /opt/actions-runner/token)
elif [ ! -z "$GITHUB_TOKEN" ]; then
    RUNNER_TOKEN="$GITHUB_TOKEN"
else
    echo "Error: No registration token found. Set GITHUB_TOKEN environment variable or create /opt/actions-runner/token file"
    exit 1
fi

cd /opt/actions-runner

# Remove any existing runner configuration
if [ -f .runner ]; then
    echo "Removing existing runner configuration..."
    ./config.sh remove --token $RUNNER_TOKEN 2>/dev/null || true
fi

# Register the runner
echo "Registering runner: $RUNNER_NAME"
./config.sh \
    --url $GITHUB_URL \
    --token $RUNNER_TOKEN \
    --name $RUNNER_NAME \
    --labels proxmox,on-demand,lxc \
    --work _work \
    --replace \
    --unattended

if [ $? -eq 0 ]; then
    echo "Runner registered successfully"
    
    # Start the runner
    echo "Starting runner..."
    ./run.sh &
    
    # Start auto-shutdown timer
    /opt/actions-runner/auto-shutdown.sh &
    
    echo "Runner started and auto-shutdown enabled"
else
    echo "Failed to register runner"
    exit 1
fi