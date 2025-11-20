#!/bin/bash
# Generate DNS records for email authentication

source .env

DOMAIN=$(echo "$GITLAB_EMAIL_FROM" | cut -d'@' -f2)

echo "=== DNS Records Required for Email Delivery ==="
echo ""
echo "Add these records to your DNS provider:"
echo ""
echo "1. SPF Record (TXT)"
echo "   Name: @"
echo "   Type: TXT"
echo "   Value: v=spf1 ip4:${DROPLET_IP} include:_spf.${SMTP_DOMAIN} ~all"
echo ""
echo "2. DMARC Record (TXT)"
echo "   Name: _dmarc"
echo "   Type: TXT"
echo "   Value: v=DMARC1; p=quarantine; rua=mailto:${ADMIN_EMAIL}"
echo ""
echo "3. MX Record (if receiving email)"
echo "   Name: @"
echo "   Type: MX"
echo "   Priority: 10"
echo "   Value: ${GITLAB_DOMAIN}"
echo ""
echo "4. Reverse DNS (PTR) Record"
echo "   Configure in Digital Ocean droplet settings:"
echo "   Networking → Edit → Reverse DNS → ${GITLAB_DOMAIN}"
echo ""

# If using SendGrid, show additional records
if [ "$EMAIL_METHOD" = "sendgrid" ]; then
    echo "5. SendGrid Domain Authentication Records"
    echo "   Log into SendGrid → Settings → Sender Authentication"
    echo "   Follow the wizard to get your specific CNAME records"
    echo ""
fi

# If using Mailgun
if [ "$EMAIL_METHOD" = "mailgun" ]; then
    echo "5. Mailgun Domain Verification Records"
    echo "   Log into Mailgun → Sending → Domains → ${MAILGUN_DOMAIN}"
    echo "   Copy the TXT and CNAME records shown"
    echo ""
fi

echo "⚠ After adding DNS records, wait 10-60 minutes for propagation"
echo "⚠ Use 'dig TXT ${DOMAIN}' to verify SPF record"
echo "⚠ Use 'dig TXT _dmarc.${DOMAIN}' to verify DMARC record"
