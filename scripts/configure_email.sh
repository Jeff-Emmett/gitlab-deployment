#!/bin/bash
# Configure email delivery for GitLab

set -e

source .env

echo "=== Configuring GitLab Email Settings ==="

# Backup original config
sudo cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.email_backup

# Function to configure SMTP
configure_smtp() {
    echo "Configuring SMTP email delivery..."
    sudo bash -c "cat >> /etc/gitlab/gitlab.rb" <<EOF

### Email Configuration - SMTP ###
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = '${GITLAB_EMAIL_FROM}'
gitlab_rails['gitlab_email_display_name'] = '${GITLAB_EMAIL_DISPLAY_NAME}'
gitlab_rails['gitlab_email_reply_to'] = '${GITLAB_EMAIL_REPLY_TO}'

# SMTP Settings
gitlab_rails['smtp_enable'] = ${SMTP_ENABLED}
gitlab_rails['smtp_address'] = "${SMTP_ADDRESS}"
gitlab_rails['smtp_port'] = ${SMTP_PORT}
gitlab_rails['smtp_user_name'] = "${SMTP_USER_NAME}"
gitlab_rails['smtp_password'] = "${SMTP_PASSWORD}"
gitlab_rails['smtp_domain'] = "${SMTP_DOMAIN}"
gitlab_rails['smtp_authentication'] = "${SMTP_AUTHENTICATION}"
gitlab_rails['smtp_enable_starttls_auto'] = ${SMTP_ENABLE_STARTTLS_AUTO}
gitlab_rails['smtp_tls'] = ${SMTP_TLS}
gitlab_rails['smtp_openssl_verify_mode'] = '${SMTP_OPENSSL_VERIFY_MODE}'
EOF
}

# Function to configure SendGrid
configure_sendgrid() {
    echo "Configuring SendGrid email delivery..."
    sudo bash -c "cat >> /etc/gitlab/gitlab.rb" <<EOF

### Email Configuration - SendGrid ###
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = '${GITLAB_EMAIL_FROM}'
gitlab_rails['gitlab_email_display_name'] = '${GITLAB_EMAIL_DISPLAY_NAME}'
gitlab_rails['gitlab_email_reply_to'] = '${GITLAB_EMAIL_REPLY_TO}'

# SendGrid SMTP Settings
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.sendgrid.net"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "apikey"
gitlab_rails['smtp_password'] = "${SENDGRID_API_KEY}"
gitlab_rails['smtp_domain'] = "${SMTP_DOMAIN}"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
EOF
}

# Function to configure Mailgun
configure_mailgun() {
    echo "Configuring Mailgun email delivery..."
    sudo bash -c "cat >> /etc/gitlab/gitlab.rb" <<EOF

### Email Configuration - Mailgun ###
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = '${GITLAB_EMAIL_FROM}'
gitlab_rails['gitlab_email_display_name'] = '${GITLAB_EMAIL_DISPLAY_NAME}'
gitlab_rails['gitlab_email_reply_to'] = '${GITLAB_EMAIL_REPLY_TO}'

# Mailgun SMTP Settings
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mailgun.org"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "postmaster@${MAILGUN_DOMAIN}"
gitlab_rails['smtp_password'] = "${MAILGUN_API_KEY}"
gitlab_rails['smtp_domain'] = "${MAILGUN_DOMAIN}"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
EOF
}

# Function to configure AWS SES
configure_ses() {
    echo "Configuring AWS SES email delivery..."
    sudo bash -c "cat >> /etc/gitlab/gitlab.rb" <<EOF

### Email Configuration - AWS SES ###
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = '${GITLAB_EMAIL_FROM}'
gitlab_rails['gitlab_email_display_name'] = '${GITLAB_EMAIL_DISPLAY_NAME}'
gitlab_rails['gitlab_email_reply_to'] = '${GITLAB_EMAIL_REPLY_TO}'

# AWS SES SMTP Settings
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "email-smtp.${AWS_SES_REGION}.amazonaws.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "${AWS_SES_ACCESS_KEY_ID}"
gitlab_rails['smtp_password'] = "${AWS_SES_SECRET_ACCESS_KEY}"
gitlab_rails['smtp_domain'] = "${SMTP_DOMAIN}"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
EOF
}

# Configure based on EMAIL_METHOD
case $EMAIL_METHOD in
    smtp)
        configure_smtp
        ;;
    sendgrid)
        configure_sendgrid
        ;;
    mailgun)
        configure_mailgun
        ;;
    ses)
        configure_ses
        ;;
    *)
        echo "Unknown email method: $EMAIL_METHOD"
        exit 1
        ;;
esac

# Reconfigure GitLab
echo "Reconfiguring GitLab..."
sudo gitlab-ctl reconfigure

# Test email configuration
echo "Testing email configuration..."
sudo gitlab-rails console -e production <<RUBY_SCRIPT
Notify.test_email('${ADMIN_EMAIL}', 'GitLab Email Test', 'This is a test email from your GitLab instance').deliver_now
puts "Test email sent to ${ADMIN_EMAIL}"
RUBY_SCRIPT

echo "✓ Email configuration complete"
echo "⚠ Check your inbox at ${ADMIN_EMAIL} for test email"
echo "⚠ Check spam folder if not received"
