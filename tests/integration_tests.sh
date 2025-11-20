#!/bin/bash
# Run all integration tests

source .env

echo "=== GitLab Integration Tests ==="

FAILED=0

# Test 1: HTTP Response
echo -n "Testing HTTP response... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${GITLAB_DOMAIN}")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ PASS"
else
    echo "✗ FAIL (HTTP $HTTP_CODE)"
    FAILED=$((FAILED + 1))
fi

# Test 2: SSL Certificate
echo -n "Testing SSL certificate... "
if echo | openssl s_client -servername "${GITLAB_DOMAIN}" -connect "${GITLAB_DOMAIN}:443" 2>/dev/null | grep -q "Verify return code: 0"; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 3: Services Running
echo -n "Testing GitLab services... "
if ssh root@"${DROPLET_IP}" 'gitlab-ctl status' | grep -q "run:"; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
    FAILED=$((FAILED + 1))
fi

# Test 4: Disk Space
echo -n "Testing disk space... "
DISK_USAGE=$(ssh root@"${DROPLET_IP}" "df -h / | tail -1 | awk '{print \$5}' | sed 's/%//'")
if [ "$DISK_USAGE" -lt 80 ]; then
    echo "✓ PASS (${DISK_USAGE}% used)"
else
    echo "✗ FAIL (${DISK_USAGE}% used - critically high)"
    FAILED=$((FAILED + 1))
fi

# Test 5: Email DNS Records
echo -n "Testing email DNS records... "
DOMAIN=$(echo "$GITLAB_EMAIL_FROM" | cut -d'@' -f2)
if dig +short TXT "${DOMAIN}" | grep -q "spf"; then
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
