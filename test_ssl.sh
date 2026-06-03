#!/bin/bash

# test_ssl.sh
# Verifies SSL enforcement and mTLS configurations

echo "=== Running SSL / mTLS Security Tests ==="
echo ""

# Test 1: HTTP redirects to HTTPS on reverse proxy
echo "[Test 1] Checking HTTP to HTTPS redirect..."
REDIRECT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$REDIRECT_STATUS" -eq 301 ]; then
    echo "✅ PASS: Port 80 successfully redirects to 443 (HTTP 301)."
else
    echo "❌ FAIL: Expected 301 redirect from port 80, got $REDIRECT_STATUS."
fi

# Test 2: Gateway rejects connections without valid client cert
echo "[Test 2] Checking Gateway mTLS enforcement (missing client cert)..."
# We run curl from inside the reverse-proxy container since the gateway is internal
GATEWAY_MTLS_STATUS=$(docker exec Adopti_reverse_proxy curl -s -k -o /dev/null -w "%{http_code}" https://gateway/health 2>/dev/null)
# 400 Bad Request is returned by NGINX when a required client cert is missing
if [ "$GATEWAY_MTLS_STATUS" == "400" ] || [ "$GATEWAY_MTLS_STATUS" == "000" ]; then
    echo "✅ PASS: Gateway rejects connection without client cert."
else
    echo "❌ FAIL: Gateway allowed connection without client cert (Status: $GATEWAY_MTLS_STATUS)."
fi

# Test 3: Gateway accepts connections with valid client cert
echo "[Test 3] Checking Gateway mTLS enforcement (valid client cert)..."
GATEWAY_MTLS_SUCCESS=$(docker exec Adopti_reverse_proxy curl -s -k -o /dev/null -w "%{http_code}" --cert /etc/nginx/certs/server.crt --key /etc/nginx/certs/server.key https://gateway/health)
if [ "$GATEWAY_MTLS_SUCCESS" -eq 200 ]; then
    echo "✅ PASS: Gateway accepts connection with valid client cert."
else
    echo "❌ FAIL: Gateway rejected connection with valid client cert (Status: $GATEWAY_MTLS_SUCCESS)."
fi

echo ""
