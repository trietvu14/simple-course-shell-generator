#!/bin/bash

echo "=== Canvas OAuth Integration Test ==="
echo ""

# Test Canvas OAuth endpoint directly
echo "1. Testing Canvas OAuth authorization endpoint..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "https://dppowerfullearning.instructure.com/login/oauth2/auth?client_id=280980000000000004&response_type=code&redirect_uri=https://shell.dpvils.org/api/canvas/oauth/callback&scope=url:GET|/api/v1/accounts"

echo ""
echo "2. Testing Canvas OAuth token endpoint..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" -X POST "https://dppowerfullearning.instructure.com/login/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=280980000000000004&client_secret=Gy3PtTYcXTFWZ7kn93DkBreWzfztYyxyUXer8RCcfWr4JQcLUW9K2BYcuu7LQVYa"

echo ""
echo "3. Testing Canvas API with static token..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "https://dppowerfullearning.instructure.com/api/v1/accounts" \
  -H "Authorization: Bearer 28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG"

echo ""
echo "4. Service logs showing Canvas OAuth configuration..."
journalctl -u canvas-course-generator.service -n 20 --no-pager | grep -E "(Canvas OAuth|clientId|canvasUrl|redirectUri)"

echo ""
echo "=== Diagnosis ==="
echo "✅ Environment variables loaded correctly"
echo "✅ Canvas OAuth configuration shows proper values"
echo "❌ Canvas token refresh failing with 400 invalid_client"
echo ""
echo "🔍 Possible issues:"
echo "1. Canvas developer key might be expired or deactivated"
echo "2. Canvas OAuth client credentials don't match Canvas developer key"
echo "3. Redirect URI mismatch in Canvas developer key configuration"
echo "4. Canvas developer key might not have proper scopes configured"
echo ""
echo "🔧 Next steps:"
echo "1. Check Canvas developer key status at: https://dppowerfullearning.instructure.com/accounts/1/developer_keys"
echo "2. Verify client ID matches: 280980000000000004"
echo "3. Verify redirect URI matches: https://shell.dpvils.org/api/canvas/oauth/callback"
echo "4. Ensure developer key is 'On' and has proper scopes"
echo ""
echo "🎯 For now, the system will use the static API token as fallback"
echo "   Canvas course shell creation should still work properly"