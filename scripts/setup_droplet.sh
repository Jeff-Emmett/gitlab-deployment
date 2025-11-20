#!/bin/bash
# Initial droplet setup and hardening

set -e

source .env

echo "=== Setting up Digital Ocean Droplet ==="

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl openssh-server ca-certificates tzdata perl ufw

# Configure firewall
sudo ufw --force enable
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https

# Install postfix for email (lightweight MTA)
sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix

# Set timezone
sudo timedatectl set-timezone UTC

# Create swap file if not exists (helps with 4GB RAM)
if [ ! -f /swapfile ]; then
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# Install monitoring tools
sudo apt install -y htop ncdu

echo "✓ Droplet setup complete"
