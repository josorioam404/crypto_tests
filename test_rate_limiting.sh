#!/bin/bash

# test_rate_limiting.sh
# Verifies DDoS protection mechanisms

echo "=== Running Rate Limiting Security Tests ==="
echo ""

# Test 1: Rate limiting on Gateway (/api/pets/stats)
echo "[Test 1] Checking Gateway zone (api_general) on /api/pets/stats..."
# Send 25 rapid requests in parallel
rm -f /tmp/gateway_status.log

for i in {1..25}; do
    curl -s -k -o /dev/null -w "%{http_code}\n" https://localhost/api/pets/stats >> /tmp/gateway_status.log &
done
wait

SUCCESS_COUNT=$(grep -c "200" /tmp/gateway_status.log)
RATE_LIMITED_COUNT=$(grep -c "429" /tmp/gateway_status.log)

echo "   Successful requests (200): $SUCCESS_COUNT"
echo "   Rate-limited requests (429): $RATE_LIMITED_COUNT"

if [ "$RATE_LIMITED_COUNT" -gt 0 ]; then
    echo "✅ PASS: DDoS protection active on Gateway endpoints."
else
    echo "❌ FAIL: No requests were rate-limited. Gateway zone might be disabled."
fi

# Test 2: Rate limiting on Reverse Proxy (/api/session)
echo "[Test 2] Checking Reverse Proxy zone (auth_limit) on /api/session..."
# Send 20 rapid requests in parallel
rm -f /tmp/proxy_status.log

for i in {1..20}; do
    curl -s -X POST -k -o /dev/null -w "%{http_code}\n" https://localhost/api/session >> /tmp/proxy_status.log &
done
wait

SUCCESS_COUNT=$(grep -cv "429" /tmp/proxy_status.log)
RATE_LIMITED_COUNT=$(grep -c "429" /tmp/proxy_status.log)

echo "   Non-rate-limited requests: $SUCCESS_COUNT"
echo "   Rate-limited requests (429): $RATE_LIMITED_COUNT"

if [ "$RATE_LIMITED_COUNT" -gt 0 ]; then
    echo "✅ PASS: DDoS protection active on Frontend API endpoints."
else
    echo "❌ FAIL: No requests were rate-limited. Auth limit zone might be disabled."
fi

echo ""
