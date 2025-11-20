#!/bin/bash
# Configure Let's Encrypt SSL

set -e

source .env

echo "=== Configuring SSL with Let's Encrypt ==="

# Backup original config
sudo cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.backup

# Configure Let's Encrypt
sudo bash -c "cat >> /etc/gitlab/gitlab.rb" <<EOF

# Let's Encrypt Configuration
letsencrypt['enable'] = true
letsencrypt['contact_emails'] = ['${ADMIN_EMAIL}']
letsencrypt['auto_renew'] = true
letsencrypt['auto_renew_hour'] = 2
letsencrypt['auto_renew_minute'] = 30
letsencrypt['auto_renew_day_of_month'] = "*/7"

# Redirect HTTP to HTTPS
nginx['redirect_http_to_https'] = true
nginx['ssl_protocols'] = "TLSv1.2 TLSv1.3"
EOF

# Reconfigure GitLab
sudo gitlab-ctl reconfigure

echo "✓ SSL configured successfully"
