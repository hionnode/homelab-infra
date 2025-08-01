#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential utilities
echo "Installing essential utilities..."
sudo apt-get install -y curl wget gnupg lsb-release ca-certificates apt-transport-https software-properties-common

# Install Node.js LTS
echo "Installing Node.js LTS..."
# Add the NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Git
echo "Installing Git..."
sudo apt-get install -y git

# Install Docker
echo "Installing Docker..."
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add the current user to the docker group
echo "Adding current user to the docker group..."
sudo usermod -aG docker ${USER}

echo "Installation complete. Please log out and log back in for the Docker group changes to take effect."
