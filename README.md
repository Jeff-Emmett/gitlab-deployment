# GitLab Self-Hosting Deployment

Complete automation for deploying production-ready GitLab on Digital Ocean with custom domain, SSL, email delivery, automated backups, and monitoring.

## Features

- ✅ Automated GitLab CE installation
- ✅ Let's Encrypt SSL with auto-renewal
- ✅ Multiple email provider support (Gmail, SendGrid, Mailgun, AWS SES)
- ✅ Automated daily backups with cloud storage option
- ✅ Health monitoring scripts
- ✅ Security hardening and firewall rules
- ✅ Performance tuning for 4GB+ RAM droplets
- ✅ Comprehensive testing suite
- ✅ Complete documentation

## Quick Start

### 1. Prerequisites

- Digital Ocean droplet (4GB RAM minimum, 8GB recommended)
- Domain name with DNS access
- Email provider account (see docs/EMAIL_SETUP.md)
- SSH access to droplet

### 2. Local Setup

```bash
# Clone or create this directory structure
cd gitlab-deployment

# Copy environment template
cp .env.example .env

# Edit with your configuration
nano .env

# Make scripts executable
chmod +x scripts/*.sh tests/*.sh
```

### 3. Configure DNS

**Before deployment**, add this A record to your DNS:

```
Type: A
Name: gitlab (or @ for root domain)
Value: YOUR_DROPLET_IP
TTL: 3600
```

Wait for DNS propagation: `dig gitlab.yourdomain.com`

### 4. Deploy GitLab

Run scripts in order:

```bash
# 1. Setup droplet
ssh root@your_droplet_ip "bash -s" < scripts/setup_droplet.sh

# 2. Install GitLab (takes 5-10 minutes)
ssh root@your_droplet_ip "bash -s" < scripts/install_gitlab.sh

# 3. Configure SSL
ssh root@your_droplet_ip "bash -s" < scripts/configure_ssl.sh

# 4. Configure email (see docs/EMAIL_SETUP.md first!)
ssh root@your_droplet_ip "bash -s" < scripts/configure_email.sh

# 5. Setup email DNS records
./scripts/setup_dns_records.sh
# Follow output to add DNS records

# 6. Test email
./scripts/test_email.sh
```

### 5. First Login

```bash
# Get initial password
ssh root@your_droplet_ip 'cat /etc/gitlab/initial_root_password'

# Visit your GitLab
https://gitlab.yourdomain.com

# Login as root with the password above
# IMMEDIATELY change the password!
```

### 6. Setup Automated Backups

```bash
ssh root@your_droplet_ip
crontab -e

# Add daily backup at 2 AM
0 2 * * * /root/gitlab-deployment/scripts/backup_gitlab.sh >> /var/log/gitlab_backup.log 2>&1
```

## Documentation

- **[Deployment Guide](docs/DEPLOYMENT.md)** - Complete step-by-step deployment
- **[Email Setup](docs/EMAIL_SETUP.md)** - Email configuration for all providers
- **[Testing Guide](docs/TESTING.md)** - Comprehensive testing procedures
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## Requirements

### Minimum
- 4GB RAM, 2 vCPU cores
- 25GB SSD storage
- Ubuntu 22.04 LTS

### Recommended
- 8GB RAM, 4 vCPU cores
- 50GB SSD storage
- Ubuntu 22.04 LTS

### For 50+ Users
- 16GB RAM, 8 vCPU cores
- 100GB SSD storage
- Ubuntu 22.04 LTS

## Project Structure

```
gitlab-deployment/
├── README.md                    # This file
├── .env.example                 # Environment variables template
├── scripts/
│   ├── setup_droplet.sh        # Initial server setup
│   ├── install_gitlab.sh       # GitLab installation
│   ├── configure_ssl.sh        # SSL certificate setup
│   ├── configure_email.sh      # Email configuration
│   ├── setup_dns_records.sh    # DNS record generator
│   ├── test_email.sh           # Email testing suite
│   ├── backup_gitlab.sh        # Backup automation
│   └── health_check.sh         # Health monitoring
├── configs/
│   └── gitlab.rb.template      # GitLab configuration template
├── docs/
│   ├── DEPLOYMENT.md           # Deployment guide
│   ├── EMAIL_SETUP.md          # Email setup guide
│   ├── TESTING.md              # Testing procedures
│   └── TROUBLESHOOTING.md      # Troubleshooting guide
└── tests/
    └── integration_tests.sh    # Automated testing
```

## Security Notes

1. **Change root password immediately** after first login
2. **Enable 2FA** for all admin accounts
3. **Review SSH key access** regularly
4. **Keep GitLab updated** monthly
5. **Monitor logs** for suspicious activity
6. **Use strong passwords** for all accounts
7. **Rotate credentials** every 90 days

## Backup & Recovery

### Create Backup
```bash
ssh root@your_droplet_ip
sudo gitlab-backup create
```

### Restore Backup
```bash
# Stop services
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq

# Restore (replace TIMESTAMP)
sudo gitlab-backup restore BACKUP=TIMESTAMP

# Restart
sudo gitlab-ctl restart
sudo gitlab-rake gitlab:check SANITIZE=true
```

Backups stored in: `/var/opt/gitlab/backups/`

## Updating GitLab

```bash
# SSH to droplet
ssh root@your_droplet_ip

# Create backup first!
sudo gitlab-backup create

# Update
sudo apt update
sudo apt upgrade gitlab-ce

# Verify
sudo gitlab-rake gitlab:check
```

## Monitoring

Run health checks:
```bash
ssh root@your_droplet_ip '/root/gitlab-deployment/scripts/health_check.sh'
```

Set up automated monitoring:
```bash
# Edit crontab
crontab -e

# Add hourly health check
0 * * * * /root/gitlab-deployment/scripts/health_check.sh >> /var/log/gitlab_health.log 2>&1
```

## Cost Estimate (Monthly)

- **Droplet (4GB):** $24/month
- **Droplet (8GB):** $48/month
- **Email (SendGrid):** Free (100 emails/day)
- **Email (Mailgun):** Free (5,000 emails/month)
- **Backups (DO Spaces):** $5/month (250GB)
- **Domain:** $10-15/year

**Total:** ~$24-48/month

## Common Issues

### GitLab won't start
```bash
# Check memory and disk space
free -h
df -h

# Check logs
sudo gitlab-ctl tail
```

### SSL certificate issues
```bash
# Verify DNS
dig gitlab.yourdomain.com

# Renew certificate
sudo gitlab-ctl renew-le-certs
```

### Email not working
See **[docs/EMAIL_SETUP.md](docs/EMAIL_SETUP.md)** for comprehensive troubleshooting.

### More help
See **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**

## Support

- **Documentation:** docs/
- **GitLab Docs:** docs.gitlab.com
- **GitLab Forum:** forum.gitlab.com
- **Digital Ocean Community:** digitalocean.com/community

## License

This deployment configuration is provided as-is for personal and commercial use.

## Contributing

Improvements welcome! Please test thoroughly before submitting changes.

## Next Steps After Deployment

1. Import existing repositories
2. Set up CI/CD pipelines
3. Configure integrations (Slack, Discord, etc.)
4. Set up project templates
5. Configure issue boards and milestones
6. Explore GitLab Container Registry (optional)
7. Set up GitLab Pages for documentation (optional)

## Resources

- [GitLab Documentation](https://docs.gitlab.com)
- [Digital Ocean Tutorials](https://www.digitalocean.com/community/tutorials)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Git Documentation](https://git-scm.com/doc)

---

**Version:** 1.0.0
**Last Updated:** 2024
