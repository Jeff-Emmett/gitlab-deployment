# GitLab Testing Procedures

## Pre-Deployment Tests (Local Environment)

Run these tests before deploying to production.

### 1. DNS Resolution Test
```bash
# Test A record
dig gitlab.yourdomain.com

# Should return your droplet IP
# Alternative using nslookup
nslookup gitlab.yourdomain.com
```

**Expected Result:** Your droplet IP address should be returned.

### 2. SSH Access Test
```bash
# Test SSH connection with verbose output
ssh -v root@your_droplet_ip

# Should connect without errors
```

**Expected Result:** Successful SSH connection to droplet.

### 3. Port Accessibility Test
```bash
# Test required ports
nc -zv your_droplet_ip 22    # SSH
nc -zv your_droplet_ip 80    # HTTP
nc -zv your_droplet_ip 443   # HTTPS

# All should show "succeeded"
```

**Expected Result:** All three ports should be accessible.

## Post-Deployment Tests

Run these tests after each deployment step.

### 1. Service Status Check
```bash
ssh root@your_droplet_ip 'gitlab-ctl status'
```

**Expected Result:** All services should be "run" status.

### 2. HTTPS/SSL Test
```bash
# Test HTTPS response
curl -I https://gitlab.yourdomain.com

# Should return 200 OK with HTTPS headers

# Test SSL certificate
openssl s_client -connect gitlab.yourdomain.com:443 -servername gitlab.yourdomain.com

# Should show valid certificate from Let's Encrypt
```

**Expected Result:**
- HTTP 200 OK response
- Valid Let's Encrypt certificate
- No SSL warnings

### 3. Web Interface Test

**Manual Steps:**
1. Visit `https://gitlab.yourdomain.com` in browser
2. Verify no certificate warnings
3. Should see GitLab login page
4. Get root password: `ssh root@your_droplet_ip 'cat /etc/gitlab/initial_root_password'`
5. Login with username `root` and the password
6. Should successfully reach GitLab dashboard

**Expected Result:** Successful login and functional UI.

### 4. Git Operations Test (HTTPS)
```bash
# Create a test repository via web UI first
# Then test clone:
git clone https://gitlab.yourdomain.com/root/test-repo.git
cd test-repo

# Create test file
echo "# Test Repository" > README.md

# Commit and push
git add README.md
git commit -m "Initial commit"
git push origin main
```

**Expected Result:** Successful clone, commit, and push operations.

### 5. SSH Git Access Test
```bash
# First, add your SSH key in GitLab UI:
# User Settings → SSH Keys → Add new key

# Test SSH connection
ssh -T git@gitlab.yourdomain.com
# Should return: Welcome to GitLab, @username!

# Clone via SSH
git clone git@gitlab.yourdomain.com:root/test-repo.git test-repo-ssh
cd test-repo-ssh

# Make changes
echo "SSH test" >> README.md
git add README.md
git commit -m "SSH test commit"
git push origin main
```

**Expected Result:** Successful SSH authentication and git operations.

### 6. Email Delivery Test

Run the comprehensive email test script:
```bash
./scripts/test_email.sh
```

**Manual Email Test:**
```bash
ssh root@your_droplet_ip
gitlab-rails console

# Send test email
Notify.test_email('your@email.com', 'GitLab Test', 'This is a test').deliver_now
exit

# Check logs
tail -f /var/log/gitlab/gitlab-rails/production.log | grep -i mail
```

**Expected Result:**
- Test email received within 5 minutes
- Email NOT in spam folder
- Email has correct from address
- All DNS records verified (SPF, DKIM, DMARC)

### 7. Backup Test
```bash
# Run backup script
ssh root@your_droplet_ip '/root/gitlab-deployment/scripts/backup_gitlab.sh'

# Verify backup file created
ssh root@your_droplet_ip 'ls -lh /var/opt/gitlab/backups/'

# Should show recent .tar file
```

**Expected Result:**
- Backup completes without errors
- Backup file exists in /var/opt/gitlab/backups/
- Backup file size is reasonable (not empty)

### 8. Health Check Test
```bash
# Run health check script
ssh root@your_droplet_ip '/root/gitlab-deployment/scripts/health_check.sh'
```

**Expected Result:**
- All services running
- Adequate disk space (>20% free)
- Reasonable memory usage (<80%)
- Health endpoint returns success
- Valid SSL certificate

## Integration Tests

### GitLab Rake Checks
```bash
ssh root@your_droplet_ip 'sudo gitlab-rake gitlab:check'
```

**Expected Result:** All checks should pass or show warnings only (no failures).

### GitLab Environment Info
```bash
ssh root@your_droplet_ip 'sudo gitlab-rake gitlab:env:info'
```

Review output for correct configuration.

### Database Connectivity
```bash
ssh root@your_droplet_ip 'sudo gitlab-rake gitlab:db:check'
```

**Expected Result:** Database connection successful.

## Monitoring Checklist

Create this checklist for regular monitoring:

- [ ] GitLab web UI accessible and responsive
- [ ] SSL certificate valid and auto-renewing
- [ ] Git clone/push operations work via HTTPS
- [ ] Git clone/push operations work via SSH
- [ ] Email delivery working (test weekly)
- [ ] Emails not going to spam
- [ ] Backups completing successfully (check logs)
- [ ] All GitLab services running
- [ ] Disk space adequate (>20% free)
- [ ] Memory usage reasonable (<80%)
- [ ] No errors in logs
- [ ] SSL certificate expiry > 30 days
- [ ] DNS records still valid

## Automated Testing Script

Create `tests/integration_tests.sh`:

```bash
#!/bin/bash
# Run all integration tests

source .env

echo "=== GitLab Integration Tests ==="

FAILED=0

# Test 1: HTTP Response
echo -n "Testing HTTP response... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://${GITLAB_DOMAIN})
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL (HTTP $HTTP_CODE)"
    FAILED=$((FAILED + 1))
fi

# Test 2: SSL Certificate
echo -n "Testing SSL certificate... "
if echo | openssl s_client -servername ${GITLAB_DOMAIN} -connect ${GITLAB_DOMAIN}:443 2>/dev/null | grep -q "Verify return code: 0"; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 3: Services Running
echo -n "Testing GitLab services... "
if ssh root@${DROPLET_IP} 'gitlab-ctl status' | grep -q "run:"; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 4: Disk Space
echo -n "Testing disk space... "
DISK_USAGE=$(ssh root@${DROPLET_IP} "df -h / | tail -1 | awk '{print \$5}' | sed 's/%//'")
if [ "$DISK_USAGE" -lt 80 ]; then
    echo "✓ PASS (${DISK_USAGE}% used)"
else
    echo "✗ FAIL (${DISK_USAGE}% used - critically high)"
    FAILED=$((FAILED + 1))
fi

# Test 5: Email DNS Records
echo -n "Testing email DNS records... "
DOMAIN=$(echo $GITLAB_EMAIL_FROM | cut -d'@' -f2)
if dig +short TXT ${DOMAIN} | grep -q "spf"; then
    echo "✓ PASS"
else
    echo "⚠ WARNING (SPF not found)"
fi

# Summary
echo ""
echo "=== Test Summary ==="
if [ $FAILED -eq 0 ]; then
    echo "✓ All tests passed"
    exit 0
else
    echo "✗ $FAILED test(s) failed"
    exit 1
fi
```

Make executable: `chmod +x tests/integration_tests.sh`

## Production Readiness Checklist

Before declaring production ready:

- [ ] All pre-deployment tests pass
- [ ] All post-deployment tests pass
- [ ] Integration tests pass
- [ ] Email delivery works (not in spam)
- [ ] Backup and restore tested successfully
- [ ] Load testing completed satisfactorily
- [ ] Disaster recovery procedure tested
- [ ] Monitoring and alerting configured
- [ ] Documentation reviewed and updated
- [ ] Credentials rotated and secured
- [ ] Team trained on GitLab usage
- [ ] Support plan in place

## Troubleshooting Tests

If any test fails, see TROUBLESHOOTING.md for solutions.
