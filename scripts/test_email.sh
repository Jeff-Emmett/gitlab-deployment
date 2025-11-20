#!/bin/bash
# Comprehensive email testing

set -e

source .env

echo "=== GitLab Email Testing Suite ==="

# Test 1: Check SMTP connection
echo -e "\n1. Testing SMTP Connection..."
ssh root@"${DROPLET_IP}" "gitlab-rails runner \"
  smtp = Net::SMTP.new('${SMTP_ADDRESS}', ${SMTP_PORT})
  smtp.enable_starttls
  smtp.start('${SMTP_DOMAIN}', '${SMTP_USER_NAME}', '${SMTP_PASSWORD}', :login) do
    puts '✓ SMTP connection successful'
  end
\""

# Test 2: Send test email via GitLab console
echo -e "\n2. Sending test email via GitLab console..."
ssh root@"${DROPLET_IP}" "gitlab-rails runner \"
  Notify.test_email('${ADMIN_EMAIL}', 'GitLab Email Test', 'If you receive this, email is working!').deliver_now
  puts '✓ Test email queued'
\""

# Test 3: Check email logs
echo -e "\n3. Checking email delivery logs..."
ssh root@"${DROPLET_IP}" "tail -n 50 /var/log/gitlab/gitlab-rails/production.log | grep -i 'mail\|smtp\|email'"

# Test 4: Verify DNS records
echo -e "\n4. Verifying DNS records..."
DOMAIN=$(echo "$GITLAB_EMAIL_FROM" | cut -d'@' -f2)

echo "   SPF Record:"
dig +short TXT "${DOMAIN}" | grep spf || echo "   ⚠ SPF record not found"

echo "   DMARC Record:"
dig +short TXT "_dmarc.${DOMAIN}" || echo "   ⚠ DMARC record not found"

echo "   MX Record:"
dig +short MX "${DOMAIN}" || echo "   ⚠ MX record not found"

# Test 5: Check reverse DNS
echo -e "\n5. Checking reverse DNS..."
REVERSE_DNS=$(dig +short -x "${DROPLET_IP}")
if [ -n "$REVERSE_DNS" ]; then
    echo "   ✓ Reverse DNS: $REVERSE_DNS"
else
    echo "   ⚠ No reverse DNS configured (configure in Digital Ocean)"
fi

echo -e "\n=== Test Summary ==="
echo "Check your inbox at ${ADMIN_EMAIL} for test emails"
echo "If no email received, check spam folder and review logs above"
