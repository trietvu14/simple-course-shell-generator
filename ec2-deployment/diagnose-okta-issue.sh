#!/bin/bash

echo "=== Canvas Course Shell Generator - Okta Issue Diagnosis ==="
echo "Diagnosing Okta authentication redirect issue..."

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Checking current file contents..."
echo "--- Current okta-config.ts ---"
if [ -f "$TARGET_DIR/client/src/lib/okta-config.ts" ]; then
    cat "$TARGET_DIR/client/src/lib/okta-config.ts"
else
    echo "❌ File not found"
fi

echo ""
echo "--- Current App.tsx (Security component) ---"
if [ -f "$TARGET_DIR/client/src/App.tsx" ]; then
    grep -A 10 -B 5 "Security" "$TARGET_DIR/client/src/App.tsx" || echo "No Security component found"
else
    echo "❌ File not found"
fi

echo ""
echo "--- Current main.tsx ---"
if [ -f "$TARGET_DIR/client/src/main.tsx" ]; then
    cat "$TARGET_DIR/client/src/main.tsx"
else
    echo "❌ File not found"
fi

echo ""
echo "2. Checking environment variables..."
if [ -f "$TARGET_DIR/.env" ]; then
    grep "OKTA" "$TARGET_DIR/.env" || echo "No OKTA variables found"
else
    echo "❌ .env file not found"
fi

echo ""
echo "3. Checking service status..."
systemctl status canvas-course-generator.service --no-pager -l | tail -20

echo ""
echo "4. Checking for build cache..."
if [ -d "$TARGET_DIR/dist" ]; then
    echo "✓ Build cache exists at: $TARGET_DIR/dist"
    ls -la "$TARGET_DIR/dist"
else
    echo "❌ No build cache found"
fi

echo ""
echo "5. Checking node_modules for Okta packages..."
if [ -d "$TARGET_DIR/node_modules/@okta" ]; then
    echo "✓ Okta packages found:"
    ls -la "$TARGET_DIR/node_modules/@okta"
else
    echo "❌ Okta packages not found"
fi

echo ""
echo "=== Diagnosis complete ==="
echo "Next steps:"
echo "1. Verify the okta-config.ts file has the correct issuer URL"
echo "2. Ensure App.tsx has the Security component"
echo "3. Check that .env has OKTA_ISSUER variable"
echo "4. Clear browser cache and try again"