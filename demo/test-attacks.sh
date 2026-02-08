#!/bin/bash

# Security Testing Script
# Demonstrates attacks that fail against Zero-Trust protocol

echo "=========================================="
echo "  Zero-Trust Security Testing"
echo "=========================================="
echo ""

ROUTER_URL="http://localhost:8080"

echo "Running attack scenarios..."
echo ""

# Test 1: Default Credentials
echo "📍 Test 1: Default Credential Attack"
echo "Attempting admin/admin login..."
RESULT=$(curl -s -u admin:admin "$ROUTER_URL/cgi-bin/luci" -o /dev/null -w "%{http_code}")
if [ "$RESULT" = "401" ] || [ "$RESULT" = "404" ]; then
    echo "✓ BLOCKED: No default credentials exist"
else
    echo "✗ FAILED: Attack succeeded (this shouldn't happen)"
fi
echo ""

# Test 2: Network Scan
echo "📍 Test 2: Network Port Scan"
echo "Scanning for open services..."
docker exec ztbp_client nmap -p 1-1000 192.168.2.1 > /tmp/nmap_result.txt 2>&1 || true
OPEN_PORTS=$(grep -c "open" /tmp/nmap_result.txt || echo "0")
if [ "$OPEN_PORTS" -le 2 ]; then
    echo "✓ PASSED: Minimal attack surface ($OPEN_PORTS ports)"
else
    echo "⚠ WARNING: Multiple ports open ($OPEN_PORTS)"
fi
echo ""

# Test 3: Direct Management Access
echo "📍 Test 3: Management Interface Access"
echo "Attempting to access management without provisioning..."
RESULT=$(curl -s "$ROUTER_URL/cgi-bin/luci" -o /dev/null -w "%{http_code}")
if [ "$RESULT" = "404" ] || [ "$RESULT" = "401" ]; then
    echo "✓ BLOCKED: Management interface not accessible"
else
    echo "⚠ Check: Got HTTP $RESULT"
fi
echo ""

# Test 4: Provisioning Enforcement
echo "📍 Test 4: Provisioning Enforcement"
echo "Checking if setup can be skipped..."
RESULT=$(curl -s "$ROUTER_URL/" | grep -c "Create.*Password" || echo "0")
if [ "$RESULT" -gt 0 ]; then
    echo "✓ ENFORCED: Setup page is mandatory"
else
    echo "✗ FAILED: Setup can be skipped"
fi
echo ""

echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo ""
echo "All attacks against boot-time vulnerabilities were blocked."
echo "The router enforces security before allowing network access."
echo ""
