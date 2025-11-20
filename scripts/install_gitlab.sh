#!/bin/bash
# Install and configure GitLab

set -e

source .env

echo "=== Installing GitLab CE ==="

# Add GitLab repository
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

# Install GitLab
sudo EXTERNAL_URL="https://${GITLAB_DOMAIN}" apt install -y gitlab-ce

# Wait for GitLab to start
echo "Waiting for GitLab to initialize..."
sleep 30

echo "✓ GitLab installed successfully"
echo "Initial root password location: /etc/gitlab/initial_root_password"
