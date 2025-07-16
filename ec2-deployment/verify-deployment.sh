#!/bin/bash

echo "=== Canvas Course Shell Generator - Deployment Verification ==="
echo "Checking current deployment status..."

# Check if files exist
echo "1. Checking key files..."
if [ -f "/home/ubuntu/canvas-course-generator/client/src/lib/okta-config.ts" ]; then
    echo "✓ okta-config.ts exists"
    echo "   Issuer URL: $(grep 'issuer:' /home/ubuntu/canvas-course-generator/client/src/lib/okta-config.ts)"
else
    echo "✗ okta-config.ts missing"
fi

if [ -f "/home/ubuntu/canvas-course-generator/client/src/App.tsx" ]; then
    echo "✓ App.tsx exists"
    echo "   Security component: $(grep -A 2 'Security' /home/ubuntu/canvas-course-generator/client/src/App.tsx | head -n 3)"
else
    echo "✗ App.tsx missing"
fi

if [ -f "/home/ubuntu/canvas-course-generator/client/src/main.tsx" ]; then
    echo "✓ main.tsx exists"
    echo "   No Security component: $(grep -c 'Security' /home/ubuntu/canvas-course-generator/client/src/main.tsx || echo '0')"
else
    echo "✗ main.tsx missing"
fi

if [ -d "/home/ubuntu/canvas-course-generator/attached_assets" ]; then
    echo "✓ attached_assets directory exists"
    echo "   Canvas logo: $(ls -la /home/ubuntu/canvas-course-generator/attached_assets/Canvas_logo_single_mark_*.png 2>/dev/null || echo 'not found')"
else
    echo "✗ attached_assets directory missing"
fi

# Check service status
echo ""
echo "2. Checking service status..."
systemctl status canvas-course-generator.service --no-pager -l

# Check if build directory exists and clear it
echo ""
echo "3. Checking build cache..."
if [ -d "/home/ubuntu/canvas-course-generator/dist" ]; then
    echo "✓ Build directory exists, clearing cache..."
    rm -rf /home/ubuntu/canvas-course-generator/dist/*
    echo "   Cache cleared"
else
    echo "✗ Build directory not found"
fi

# Check node modules
echo ""
echo "4. Checking node modules..."
if [ -d "/home/ubuntu/canvas-course-generator/node_modules" ]; then
    echo "✓ Node modules exist"
else
    echo "✗ Node modules missing - run npm install"
fi

# Restart service
echo ""
echo "5. Restarting service..."
sudo systemctl restart canvas-course-generator.service

echo ""
echo "=== Deployment verification complete ==="
echo "If issues persist, try clearing browser cache and hard refresh (Ctrl+F5)"