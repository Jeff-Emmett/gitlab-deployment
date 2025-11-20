# GitLab Deployment Guide

## Prerequisites

- Digital Ocean account with droplet created (4GB RAM minimum)
- Domain name with DNS access
- Email provider account (Gmail, SendGrid, Mailgun, or AWS SES)
- Local machine with SSH access

## Local Setup

1. Clone this repository or create the directory structure
2. Copy `.env.example` to `.env`
3. Fill in your environment variables (see EMAIL_SETUP.md for email config)
4. Make scripts executable:
   ```bash
   chmod +x scripts/*.sh
   ```

## DNS Configuration (BEFORE DEPLOYMENT)

Configure your DNS before running scripts:

### 1. GitLab Domain (A Record)
- Name: `gitlab` (or `@` for root domain)
- Type: A
- Value: Your droplet IP address
- TTL: 3600

### 2. Wait for DNS Propagation
Check with: `dig gitlab.yourdomain.com`

Expected output should show your droplet IP.

## Deployment Steps

### Step 1: Initial Droplet Setup
```bash
ssh root@your_droplet_ip "bash -s" < scripts/setup_droplet.sh
```

This script:
- Updates system packages
- Configures firewall (UFW)
- Creates swap file for memory management
- Installs essential tools

### Step 2: Install GitLab
```bash
ssh root@your_droplet_ip "bash -s" < scripts/install_gitlab.sh
```

This script:
- Adds GitLab repository
- Installs GitLab CE
- Performs initial configuration

⏱️ This step takes 5-10 minutes.

### Step 3: Configure SSL
```bash
ssh root@your_droplet_ip "bash -s" < scripts/configure_ssl.sh
```

This script:
- Enables Let's Encrypt
- Configures automatic certificate renewal
- Enforces HTTPS

### Step 4: Configure Email (CRITICAL)

Email is required for GitLab to function properly.

1. **Choose email provider** (see docs/EMAIL_SETUP.md for details):
   - Gmail (testing only, 500 emails/day limit)
   - SendGrid (recommended for production, 100 emails/day free)
   - Mailgun (5,000 emails/month free)
   - AWS SES (best for scale, $0.10/1000 emails)

2. **Update .env with email settings**

3. **Run email configuration:**
   ```bash
   ssh root@your_droplet_ip "bash -s" < scripts/configure_email.sh
   ```

4. **Configure DNS records for email:**
   ```bash
   ./scripts/setup_dns_records.sh
   ```
   Follow the output to add SPF, DMARC, and DKIM records to your DNS.

5. **Configure Reverse DNS in Digital Ocean:**
   - Go to your droplet → Networking tab
   - Click Edit next to your IP address
   - Set Reverse DNS to: `gitlab.yourdomain.com`

6. **Wait for DNS propagation (10-60 minutes)**

7. **Test email delivery:**
   ```bash
   ./scripts/test_email.sh
   ```

8. **Verify test email received** (check spam folder too)

⚠️ **DO NOT PROCEED** until email is working - GitLab won't function properly without it.

### Step 5: Initial Login

1. Visit `https://gitlab.yourdomain.com`
2. Get initial root password:
   ```bash
   ssh root@your_droplet_ip 'cat /etc/gitlab/initial_root_password'
   ```
3. Login as `root` with that password
4. **Immediately change the password**
5. Set up your user account
6. Configure 2FA (recommended)

### Step 6: Configure Automated Backups

```bash
# Add to crontab on the droplet
ssh root@your_droplet_ip
crontab -e

# Add this line (daily backup at 2 AM):
0 2 * * * /root/gitlab-deployment/scripts/backup_gitlab.sh >> /var/log/gitlab_backup.log 2>&1
```

Optional: Configure cloud backup to Digital Ocean Spaces or S3
- Install and configure s3cmd
- Update GITLAB_BACKUP_BUCKET in .env
- Backups will automatically upload to cloud storage

### Step 7: Post-Deployment Configuration

1. **Configure Admin Settings:**
   - Admin Area → Settings → General
   - Set sign-up restrictions
   - Configure session duration
   - Set rate limits

2. **Create User Accounts:**
   - Admin Area → Users → New User
   - Or enable user registration with approval

3. **Configure SSH Keys:**
   - User Settings → SSH Keys
   - Add your public SSH key for git operations

4. **Create Your First Project:**
   - New Project → Create blank project
   - Test git clone and push

5. **Configure CI/CD Runners (Optional):**
   - Admin Area → CI/CD → Runners
   - Register a runner if you need CI/CD

## Testing

See TESTING.md for comprehensive testing procedures.

## Monitoring

Set up health check cron job:
```bash
# Check health every hour
0 * * * * /root/gitlab-deployment/scripts/health_check.sh >> /var/log/gitlab_health.log 2>&1
```

## Troubleshooting

See TROUBLESHOOTING.md for common issues and solutions.

## Security Hardening

1. **Change root password immediately after first login**
2. **Enable 2FA for all admin accounts**
3. **Review SSH key access regularly**
4. **Keep GitLab updated:**
   ```bash
   sudo apt update
   sudo apt upgrade gitlab-ce
   ```
5. **Monitor logs for suspicious activity**
6. **Set up fail2ban (optional but recommended)**

## Backup & Recovery

### Manual Backup
```bash
ssh root@your_droplet_ip
sudo gitlab-backup create
```

### Restore from Backup
```bash
# Stop processes that connect to the database
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq

# Restore (replace TIMESTAMP with your backup file timestamp)
sudo gitlab-backup restore BACKUP=TIMESTAMP

# Restart GitLab
sudo gitlab-ctl restart
sudo gitlab-rake gitlab:check SANITIZE=true
```

## Updating GitLab

```bash
# SSH into droplet
ssh root@your_droplet_ip

# Create backup before updating
sudo gitlab-backup create

# Update GitLab
sudo apt update
sudo apt upgrade gitlab-ce

# Verify update
sudo gitlab-rake gitlab:check
```

## Cost Optimization

- **Droplet Size:** Start with 4GB RAM ($24/month), scale as needed
- **Backups:** Use object storage (DO Spaces or S3) - cheaper than snapshots
- **Email:** Use SendGrid free tier (100 emails/day) or Mailgun (5,000/month)
- **Monitoring:** Use built-in Prometheus instead of external services

## Next Steps After Deployment

1. Import existing repositories
2. Set up CI/CD pipelines
3. Configure integrations (Slack, Discord, etc.)
4. Set up project templates
5. Configure issue boards and milestones
6. Explore GitLab Container Registry (optional)
7. Set up GitLab Pages for documentation (optional)
