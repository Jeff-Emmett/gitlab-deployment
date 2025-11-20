#!/bin/bash
# Health check script

set -e

source .env

echo "=== GitLab Health Check ==="

# Check GitLab services
echo "Checking GitLab services..."
sudo gitlab-ctl status

# Check disk space
echo -e "\nDisk Usage:"
df -h | grep -E '^/dev|Filesystem'

# Check memory
echo -e "\nMemory Usage:"
free -h

# Check GitLab health endpoint
echo -e "\nGitLab Health Endpoint:"
curl -s "https://${GITLAB_DOMAIN}/-/health" | jq .

# Check SSL certificate
echo -e "\nSSL Certificate:"
echo | openssl s_client -servername "${GITLAB_DOMAIN}" -connect "${GITLAB_DOMAIN}:443" 2>/dev/null | openssl x509 -noout -dates

echo "✓ Health check complete"
