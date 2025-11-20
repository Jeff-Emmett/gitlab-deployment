# Email Configuration Guide

## Overview

GitLab requires email for:
- User registration and password resets
- Notifications (commits, issues, merge requests)
- Two-factor authentication codes
- System alerts

Without proper email configuration, your GitLab instance will not function correctly.

## Email Provider Options

### Option 1: Gmail (Simple, Good for Testing)

**Pros:** Free, easy setup, reliable
**Cons:** Daily sending limits (500/day), requires app password, not recommended for production

**Setup:**
1. Enable 2FA on your Gmail account
2. Generate App Password: Google Account → Security → 2-Step Verification → App passwords
3. Select "Mail" and your device
4. Copy the 16-character password
5. Use these settings in `.env`:
   ```bash
   EMAIL_METHOD=smtp
   SMTP_ADDRESS=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER_NAME=your-email@gmail.com
   SMTP_PASSWORD=your-16-char-app-password
   SMTP_DOMAIN=gmail.com
   SMTP_AUTHENTICATION=login
   SMTP_ENABLE_STARTTLS_AUTO=true
   SMTP_TLS=false
   SMTP_OPENSSL_VERIFY_MODE=peer
   ```

### Option 2: SendGrid (Recommended for Production)

**Pros:** 100 emails/day free, excellent deliverability, good for production, easy setup
**Cons:** Requires account verification, may need to warm up domain

**Setup:**
1. Sign up at sendgrid.com
2. Verify your email address
3. Create API Key: Settings → API Keys → Create API Key
   - Give it a name
   - Select "Full Access"
   - Copy the API key (you won't see it again)
4. Authenticate domain: Settings → Sender Authentication → Domain Authentication
   - Follow wizard to add DNS records
   - This improves deliverability significantly
5. Use these settings in `.env`:
   ```bash
   EMAIL_METHOD=sendgrid
   SENDGRID_API_KEY=your_sendgrid_api_key
   SMTP_DOMAIN=yourdomain.com
   ```

### Option 3: Mailgun (Good Balance)

**Pros:** 5,000 emails/month free, good API, flexible, reliable
**Cons:** Requires domain verification, slight learning curve

**Setup:**
1. Sign up at mailgun.com
2. Add and verify your domain
   - Go to Sending → Domains → Add New Domain
   - Add the DNS records provided (TXT, CNAME, MX)
   - Wait for verification (usually 5-10 minutes)
3. Get SMTP credentials from domain settings
4. Use these settings in `.env`:
   ```bash
   EMAIL_METHOD=mailgun
   MAILGUN_API_KEY=your_mailgun_api_key
   MAILGUN_DOMAIN=mg.yourdomain.com
   SMTP_DOMAIN=yourdomain.com
   ```

### Option 4: AWS SES (Best for Scale)

**Pros:** Highly scalable, extremely cheap ($0.10/1000 emails), reliable, production-grade
**Cons:** Requires AWS account, starts in sandbox mode, more complex setup

**Setup:**
1. Create AWS account
2. Go to AWS SES console
3. Verify your domain and email addresses
4. Request production access if needed (for sending to any address)
5. Create SMTP credentials: Account Dashboard → SMTP Settings → Create SMTP Credentials
6. Use these settings in `.env`:
   ```bash
   EMAIL_METHOD=ses
   AWS_SES_ACCESS_KEY_ID=your_access_key
   AWS_SES_SECRET_ACCESS_KEY=your_secret_key
   AWS_SES_REGION=us-east-1
   SMTP_DOMAIN=yourdomain.com
   ```

## DNS Configuration (CRITICAL)

Without proper DNS records, your emails WILL go to spam or bounce entirely.

### 1. SPF Record (Sender Policy Framework)
Tells receiving servers that your droplet is authorized to send email for your domain.

```
Type: TXT
Name: @ (or leave blank for root domain)
Value: v=spf1 ip4:YOUR_DROPLET_IP include:_spf.gmail.com ~all
TTL: 3600
```

Replace `YOUR_DROPLET_IP` with your actual droplet IP.

If using SendGrid, use: `v=spf1 include:sendgrid.net ~all`
If using Mailgun, use: `v=spf1 include:mailgun.org ~all`

### 2. DMARC Record (Domain-based Message Authentication)
Tells receiving servers how to handle emails that fail authentication.

```
Type: TXT
Name: _dmarc
Value: v=DMARC1; p=quarantine; rua=mailto:admin@yourdomain.com
TTL: 3600
```

This tells servers to quarantine suspicious emails and send reports to your admin email.

### 3. DKIM Record (DomainKeys Identified Mail)
Digital signature for your emails. Get from your email provider:

- **SendGrid:** Settings → Sender Authentication → Domain Authentication → Follow wizard
- **Mailgun:** Domains → Select Domain → Domain Settings → Copy CNAME records
- **AWS SES:** Verified Identities → Select Domain → DKIM tab → Copy records

These will be CNAME records that look like:
```
Type: CNAME
Name: s1._domainkey
Value: s1.domainkey.u1234567.wl.sendgrid.net
TTL: 3600
```

### 4. Reverse DNS (PTR Record)
Links your IP back to your domain. Configure in Digital Ocean:

1. Go to your droplet in Digital Ocean dashboard
2. Click "Networking" tab
3. Find your droplet's IP address
4. Click "Edit" button next to the IP
5. Enter "Reverse DNS": `gitlab.yourdomain.com`
6. Save

This is critical - many mail servers reject email from IPs without reverse DNS.

### 5. MX Record (If Receiving Email - Optional)
Only needed if you want to receive email at your domain.

```
Type: MX
Name: @ (or leave blank)
Priority: 10
Value: gitlab.yourdomain.com
TTL: 3600
```

## DNS Verification

After adding DNS records, verify them:

```bash
# Check SPF
dig TXT yourdomain.com | grep spf

# Check DMARC
dig TXT _dmarc.yourdomain.com

# Check DKIM (replace with your actual record name)
dig CNAME s1._domainkey.yourdomain.com

# Check MX
dig MX yourdomain.com

# Check Reverse DNS
dig -x YOUR_DROPLET_IP
```

Wait 10-60 minutes for DNS propagation before testing email.

## Testing Email Setup

### Quick Test via Script
```bash
./scripts/test_email.sh
```

### Manual Test via GitLab Console
```bash
ssh root@your_droplet_ip
gitlab-rails console

# In the console:
Notify.test_email('your@email.com', 'Test Subject', 'Test Body').deliver_now
exit
```

### Check Email Logs
```bash
ssh root@your_droplet_ip
tail -f /var/log/gitlab/gitlab-rails/production.log | grep -i mail
```

### Test Email Deliverability Score
1. Send test email to: check@mail-tester.com
2. Visit mail-tester.com and enter the unique address
3. Review your score (aim for 9/10 or higher)

## Troubleshooting

### Emails Going to Spam

**Check:**
- ✅ SPF record is set correctly
- ✅ DKIM is configured and passing
- ✅ DMARC is set
- ✅ Reverse DNS is configured
- ✅ Not sending from a residential IP
- ✅ Domain has been "warmed up" (start with low volume)

**Solutions:**
1. Use mail-tester.com to identify issues
2. Check your IP reputation: mxtoolbox.com/SuperTool.aspx
3. Request delisting if blacklisted
4. Switch to a dedicated email service (SendGrid, Mailgun)

### Emails Not Sending At All

**Check SMTP settings:**
```bash
ssh root@your_droplet_ip
gitlab-rails console

# Check SMTP configuration
ActionMailer::Base.smtp_settings

# Test SMTP connection
gitlab-rake gitlab:smtp:check
```

**Common issues:**
- Wrong SMTP credentials (especially with Gmail app passwords)
- Firewall blocking outbound port 587/465
- SMTP server requires TLS
- Email provider blocking connection from your IP

### Connection Refused / Timeout

1. **Check firewall allows outbound SMTP:**
   ```bash
   ssh root@your_droplet_ip
   sudo ufw status
   # Should allow outbound traffic by default
   ```

2. **Test SMTP connection manually:**
   ```bash
   telnet smtp.gmail.com 587
   # Should connect successfully
   ```

3. **Check if Digital Ocean blocks SMTP:**
   - New accounts may have SMTP blocked to prevent spam
   - Contact DO support to unblock port 25/587

### Gmail "Less Secure Apps" Error

- Gmail no longer supports "less secure apps"
- You **MUST** use an App Password
- Enable 2FA first, then generate App Password
- Use the 16-character app password, not your regular password

## Production Checklist

Before going live, verify:

- [ ] Email provider account created and verified
- [ ] API key/SMTP credentials generated and working
- [ ] Domain authenticated with email provider
- [ ] SPF record added to DNS and verified
- [ ] DKIM configured and passing
- [ ] DMARC record added to DNS and verified
- [ ] Reverse DNS configured in Digital Ocean
- [ ] Test email sent successfully
- [ ] Test email received (not in spam)
- [ ] Email deliverability score checked (mail-tester.com)
- [ ] Monitoring configured for email delivery
- [ ] Backup email method configured (optional)

## Email Provider Comparison

| Provider | Free Tier | Best For | Setup Difficulty | Deliverability |
|----------|-----------|----------|------------------|----------------|
| Gmail | 500/day | Testing | Easy | Good |
| SendGrid | 100/day | Production | Medium | Excellent |
| Mailgun | 5,000/month | Production | Medium | Excellent |
| AWS SES | 62,000/month* | Scale | Hard | Excellent |

*First year only with AWS Free Tier

## Recommended Configuration

For most self-hosted GitLab instances:

1. **Testing/Personal:** Use Gmail with App Password
2. **Small Team (<50 users):** Use SendGrid free tier
3. **Medium Team (50-500 users):** Use Mailgun or SendGrid paid
4. **Large Team (500+ users):** Use AWS SES

All require proper DNS configuration for best results.
