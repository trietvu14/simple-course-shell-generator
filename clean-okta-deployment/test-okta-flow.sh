#!/bin/bash

echo "=== Testing Okta Authentication Flow ==="

echo "1. Testing application health..."
curl -s -o /dev/null -w "Health Status: %{http_code}\n" https://shell.dpvils.org/health

echo "2. Testing root page (should redirect to Okta)..."
curl -s -I https://shell.dpvils.org/ | head -5

echo "3. Testing API endpoint (should require auth)..."
curl -s -o /dev/null -w "API Status: %{http_code}\n" https://shell.dpvils.org/api/accounts

echo "4. Testing Okta discovery endpoint..."
curl -s -I https://digitalpromise.okta.com/oauth2/default/.well-known/openid_configuration | head -3

echo "5. Checking service logs for errors..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 20 | grep -i "error\|oauth\|auth"

echo ""
echo "=== Expected Flow ==="
echo "1. User visits https://shell.dpvils.org"
echo "2. App redirects to Digital Promise Okta login"
echo "3. User authenticates with Okta"
echo "4. Okta redirects back to https://shell.dpvils.org/callback"
echo "5. App processes authentication and shows dashboard"
echo "6. Canvas API calls work with personal access token"
