# GitLab Troubleshooting Guide

## Common Issues and Solutions

### 1. GitLab Not Starting

**Symptoms:**
- Services won't start
- Services keep crashing
- 502 Bad Gateway error

**Diagnosis:**
```bash
# Check service status
sudo gitlab-ctl status

# Check logs for errors
sudo gitlab-ctl tail

# Check disk space
df -h

# Check memory
free -h
```

**Solutions:**

**A. Out of Memory:**
```bash
# Check memory usage
free -h

# If memory is full, restart services
sudo gitlab-ctl restart

# Add swap if not present
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Consider upgrading droplet size if issue persists
```

**B. Disk Space Full:**
```bash
# Check disk usage
df -h

# Find large files
sudo du -h /var | sort -rh | head -20

# Clean up old backups
sudo find /var/opt/gitlab/backups -type f -mtime +7 -delete

# Clean up logs
sudo gitlab-ctl cleanup-logs

# Consider adding more storage or upgrading droplet
```

**C. Services Not Starting:**
```bash
# Check specific service
sudo gitlab-ctl status servicename

# View service logs
sudo gitlab-ctl tail servicename

# Restart specific service
sudo gitlab-ctl restart servicename

# Full reconfigure
sudo gitlab-ctl reconfigure
```

### 2. SSL Certificate Issues

**Symptoms:**
- Certificate not issuing
- HTTPS not working
- Browser shows certificate error
- Let's Encrypt failing

**Diagnosis:**
```bash
# Check Let's Encrypt logs
sudo gitlab-ctl tail lets-encrypt

# Check certificate status
echo | openssl s_client -servername gitlab.yourdomain.com -connect gitlab.yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates

# Verify DNS is correct
dig gitlab.yourdomain.com
```

**Solutions:**

**A. DNS Not Pointing to Server:**
```bash
# Verify A record
dig gitlab.yourdomain.com

# Should return your droplet IP
# If not, update DNS and wait for propagation (up to 48 hours, usually 10-60 minutes)
```

**B. Ports Not Open:**
```bash
# Check firewall
sudo ufw status

# Allow HTTP and HTTPS
sudo ufw allow http
sudo ufw allow https
sudo ufw reload
```

**C. Manual Certificate Renewal:**
```bash
# Force certificate renewal
sudo gitlab-ctl renew-le-certs

# If fails, try reconfigure
sudo gitlab-ctl reconfigure
```

### 3. 502 Bad Gateway

**Symptoms:**
- 502 error when accessing GitLab
- Page won't load

**Diagnosis:**
```bash
# Check if services are running
sudo gitlab-ctl status

# Check nginx logs
sudo gitlab-ctl tail nginx
```

**Solutions:**

**A. Services Starting Up:**
GitLab can take 5-10 minutes to fully start. Wait and refresh.

**B. Services Crashed:**
```bash
# Restart all services
sudo gitlab-ctl restart

# Wait 5 minutes then check status
sudo gitlab-ctl status

# If still failing, check logs
sudo gitlab-ctl tail
```

**C. Nginx Configuration Error:**
```bash
# Test nginx configuration
sudo gitlab-ctl nginx -t

# Reconfigure
sudo gitlab-ctl reconfigure
```

### 4. Email Issues

**Quick Checks:**
```bash
# Test SMTP connection
gitlab-rake gitlab:smtp:check

# Send test email
gitlab-rails runner "Notify.test_email('your@email.com', 'Test', 'Body').deliver_now"

# Check email logs
tail -f /var/log/gitlab/gitlab-rails/production.log | grep -i mail
```

See docs/EMAIL_SETUP.md for comprehensive email troubleshooting.

### 5. Git Push/Pull Failures

**Symptoms:**
- Can't push or pull
- Authentication errors
- Connection refused

**Diagnosis:**
```bash
# Test HTTPS git access
git clone https://gitlab.yourdomain.com/root/test.git

# Test SSH git access
ssh -T git@gitlab.yourdomain.com
```

**Solutions:**

**A. SSH Key Issues:**
```bash
# Check SSH keys in GitLab UI: User Settings → SSH Keys

# Test SSH connection
ssh -vT git@gitlab.yourdomain.com

# Generate new SSH key if needed
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub  # Add to GitLab
```

**B. HTTPS Authentication:**
```bash
# Use personal access token instead of password
# GitLab UI: User Settings → Access Tokens → Create token

# Clone with token
git clone https://oauth2:TOKEN@gitlab.yourdomain.com/user/repo.git
```

### 6. Backup Failures

**Symptoms:**
- Backup script failing
- Backups not completing
- Backup files missing

**Diagnosis:**
```bash
# Check disk space
df -h

# Check backup logs
tail -f /var/log/gitlab_backup.log

# Try manual backup
sudo gitlab-backup create
```

**Solutions:**

**A. Out of Disk Space:**
```bash
# Clean old backups
sudo find /var/opt/gitlab/backups -type f -mtime +7 -delete

# Move backups to object storage
# Configure s3cmd for DO Spaces or AWS S3
```

**B. Permissions Issues:**
```bash
# Fix backup directory permissions
sudo chown -R git:git /var/opt/gitlab/backups
sudo chmod 0700 /var/opt/gitlab/backups
```

### 7. Slow Performance

**Symptoms:**
- GitLab is slow to load
- Git operations timeout
- High CPU or memory usage

**Diagnosis:**
```bash
# Check resource usage
htop

# Check disk I/O
iostat -x 1

# Check GitLab performance
sudo gitlab-rake gitlab:check
```

**Solutions:**

**A. Insufficient Resources:**
Upgrade your droplet:
- Minimum: 4GB RAM, 2 vCPUs
- Recommended: 8GB RAM, 4 vCPUs
- For >50 users: 16GB RAM, 8 vCPUs

**B. Database Issues:**
```bash
# Analyze and optimize database
sudo gitlab-rake db:migrate

# Vacuum database
sudo gitlab-psql -c "VACUUM ANALYZE;"
```

**C. Performance Tuning:**
Edit /etc/gitlab/gitlab.rb:
```ruby
# PostgreSQL tuning
postgresql['shared_buffers'] = "256MB"
postgresql['work_mem'] = "16MB"
postgresql['maintenance_work_mem'] = "64MB"

# Sidekiq tuning
sidekiq['max_concurrency'] = 10

# Puma tuning
puma['worker_processes'] = 2
puma['max_threads'] = 4
```

Then reconfigure:
```bash
sudo gitlab-ctl reconfigure
```

### 8. User Can't Login

**Symptoms:**
- "Invalid login or password" error
- Account locked
- 2FA issues

**Solutions:**

**A. Reset Root Password:**
```bash
# Access GitLab console
sudo gitlab-rails console

# Find and reset password
user = User.where(username: 'root').first
user.password = 'newpassword'
user.password_confirmation = 'newpassword'
user.save!
exit
```

**B. Unlock Account:**
```bash
sudo gitlab-rails console

user = User.find_by(username: 'username')
user.unlock_access!
exit
```

**C. Disable 2FA:**
```bash
sudo gitlab-rails console

user = User.find_by(username: 'username')
user.disable_two_factor!
exit
```

### 9. Database Connection Issues

**Symptoms:**
- "Could not connect to database" error
- Database timeout errors

**Solutions:**

**A. Restart Database:**
```bash
sudo gitlab-ctl restart postgresql
```

**B. Check Database Status:**
```bash
sudo gitlab-ctl status postgresql

# Check connections
sudo gitlab-psql -c "SELECT count(*) FROM pg_stat_activity;"
```

**C. Reset Database Connections:**
```bash
sudo gitlab-rake db:migrate:status
sudo gitlab-ctl restart
```

## Getting More Help

### Check System Status
```bash
# Comprehensive check
sudo gitlab-rake gitlab:check

# Environment info
sudo gitlab-rake gitlab:env:info

# Check configuration
sudo gitlab-rake gitlab:check_config
```

### View All Logs
```bash
# Tail all logs
sudo gitlab-ctl tail

# Specific service
sudo gitlab-ctl tail nginx
sudo gitlab-ctl tail gitlab-rails
sudo gitlab-ctl tail sidekiq
sudo gitlab-ctl tail postgresql
```

## Useful Commands Reference

```bash
# Service Management
sudo gitlab-ctl start
sudo gitlab-ctl stop
sudo gitlab-ctl restart
sudo gitlab-ctl status

# Configuration
sudo gitlab-ctl reconfigure
sudo gitlab-ctl show-config

# Logs
sudo gitlab-ctl tail
sudo gitlab-ctl tail SERVICE_NAME

# Maintenance
sudo gitlab-ctl cleanup-logs
sudo gitlab-rake gitlab:check

# Backups
sudo gitlab-backup create
sudo gitlab-backup restore BACKUP=timestamp

# Console Access
sudo gitlab-rails console
sudo gitlab-psql

# Updates
sudo apt update
sudo apt upgrade gitlab-ce
```

## Prevention Best Practices

1. **Monitor Resource Usage**
   - Set up alerts for disk space (<20% free)
   - Monitor memory usage
   - Check CPU load regularly

2. **Regular Backups**
   - Automate daily backups
   - Test restore procedure monthly
   - Store backups off-server

3. **Keep Updated**
   - Update GitLab monthly
   - Subscribe to security announcements
   - Test updates in staging first

4. **Monitor Logs**
   - Check logs weekly for errors
   - Set up log aggregation
   - Configure error notifications

5. **Document Everything**
   - Keep change log
   - Document customizations
   - Maintain runbook

## Emergency Contacts

- **GitLab Community Forum:** forum.gitlab.com
- **GitLab Documentation:** docs.gitlab.com
- **Digital Ocean Support:** cloud.digitalocean.com/support
