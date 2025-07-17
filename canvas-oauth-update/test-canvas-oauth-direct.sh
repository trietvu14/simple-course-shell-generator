#!/bin/bash

echo "=== Testing Canvas OAuth Direct Connection ==="
echo ""

# Test 1: Canvas OAuth authorization endpoint
echo "1. Testing Canvas OAuth authorization endpoint..."
AUTH_URL="https://dppowerfullearning.instructure.com/login/oauth2/auth?client_id=280980000000000004&response_type=code&redirect_uri=https://shell.dpvils.org/api/canvas/oauth/callback&scope=url:GET|/api/v1/accounts"
curl -s -o /dev/null -w "Authorization endpoint status: %{http_code}\n" "$AUTH_URL"

echo ""
echo "2. Testing Canvas API with static token..."
curl -s -H "Authorization: Bearer 28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG" \
     "https://dppowerfullearning.instructure.com/api/v1/accounts" \
     -w "Static token API status: %{http_code}\n" \
     -o /tmp/canvas_test_response.json

echo ""
echo "3. Canvas API response with static token:"
if [ -f /tmp/canvas_test_response.json ]; then
    head -c 200 /tmp/canvas_test_response.json
    echo ""
fi

echo ""
echo "4. Testing Canvas OAuth token endpoint with client credentials..."
TOKEN_RESPONSE=$(curl -s -X POST "https://dppowerfullearning.instructure.com/login/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=280980000000000004&client_secret=Gy3PtTYcXTFWZ7kn93DkBreWzfztYyxyUXer8RCcfWr4JQcLUW9K2BYcuu7LQVYa" \
  -w "Token endpoint status: %{http_code}")

echo "Token endpoint response:"
echo "$TOKEN_RESPONSE"

echo ""
echo "5. Canvas OAuth configuration in current service logs..."
journalctl -u canvas-course-generator.service -n 10 --no-pager | grep -E "Canvas OAuth"

echo ""
echo "=== Diagnosis ==="
echo "If static token works (200) but OAuth fails (400), the issue is likely:"
echo "- Canvas developer key configuration"
echo "- Client credentials mismatch"
echo "- Developer key not properly activated"
echo ""
echo "Check Canvas developer key at:"
echo "https://dppowerfullearning.instructure.com/accounts/1/developer_keys"
echo ""
echo "Verify:"
echo "- Key is ON (not OFF)"
echo "- Client ID: 280980000000000004"
echo "- Redirect URI: https://shell.dpvils.org/api/canvas/oauth/callback"
echo "- Scopes include account access"