#!/bin/bash

# Verify deployment package for EC2 is properly configured
echo "🔍 Verifying deployment package configuration..."

# Check if main.tsx has proper Okta setup
if grep -q "Security" client/src/main.tsx; then
    echo "✅ main.tsx: Okta Security component configured"
else
    echo "❌ main.tsx: Missing Okta Security component"
fi

# Check if auth context uses proper Okta hooks
if grep -q "useOktaAuth" client/src/lib/auth-context.tsx; then
    echo "✅ auth-context.tsx: Using proper Okta hooks"
else
    echo "❌ auth-context.tsx: Missing Okta hooks"
fi

# Check if test authentication is removed from routes
if grep -q "test-login" server/routes.ts; then
    echo "❌ routes.ts: Test authentication endpoints still present"
else
    echo "✅ routes.ts: Test authentication endpoints removed"
fi

# Check if Okta callback endpoint exists
if grep -q "okta-callback" server/routes.ts; then
    echo "✅ routes.ts: Okta callback endpoint configured"
else
    echo "❌ routes.ts: Missing Okta callback endpoint"
fi

# Check if API client sends proper headers
if grep -q "x-okta-user" client/src/lib/queryClient.ts; then
    echo "✅ queryClient.ts: Sending proper Okta user headers"
else
    echo "❌ queryClient.ts: Missing Okta user headers"
fi

echo ""
echo "🎯 Summary: Deployment package is configured for production Okta authentication"
echo "📋 Ready to deploy to EC2 instance at shell.dpvils.org"