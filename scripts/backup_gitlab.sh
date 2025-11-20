#!/bin/bash
# Automated GitLab backup script

set -e

source .env

BACKUP_DIR="/var/opt/gitlab/backups"
RETENTION_DAYS=7

echo "=== Creating GitLab Backup ==="

# Create backup
sudo gitlab-backup create STRATEGY=copy

# Find the latest backup
LATEST_BACKUP=$(find "${BACKUP_DIR}" -name "*.tar" -type f -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2-)

echo "Backup created: ${LATEST_BACKUP}"

# Optional: Upload to Digital Ocean Spaces or S3
if [ -n "${GITLAB_BACKUP_BUCKET}" ]; then
    echo "Uploading to cloud storage..."
    # Install s3cmd if not present
    if ! command -v s3cmd &> /dev/null; then
        sudo apt install -y s3cmd
    fi

    # Upload (configure s3cmd separately for DO Spaces)
    s3cmd put "${LATEST_BACKUP}" "s3://${GITLAB_BACKUP_BUCKET}/"
    echo "✓ Backup uploaded to ${GITLAB_BACKUP_BUCKET}"
fi

# Clean up old backups (keep last 7 days)
find "${BACKUP_DIR}" -name "*.tar" -type f -mtime +"${RETENTION_DAYS}" -delete

echo "✓ Backup complete"
