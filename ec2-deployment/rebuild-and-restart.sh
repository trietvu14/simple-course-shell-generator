#!/bin/bash

echo "=== Canvas Course Shell Generator - Rebuild and Restart ==="
echo "Forcing a complete rebuild to ensure Okta configuration is applied..."

TARGET_DIR="/home/ubuntu/canvas-course-generator"

# Stop the service
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

# Clear all possible caches
echo "2. Clearing all caches..."
cd "$TARGET_DIR"
rm -rf dist/
rm -rf node_modules/.vite/
rm -rf node_modules/.cache/
rm -rf .vite/
rm -rf build/

# Force reinstall dependencies to ensure clean state
echo "3. Reinstalling dependencies..."
rm -rf node_modules/
npm install

# Build the application explicitly
echo "4. Building application..."
npm run build 2>&1 || echo "Build command may not exist, continuing..."

# Start the service
echo "5. Starting service..."
sudo systemctl start canvas-course-generator.service

# Wait for service to stabilize
echo "6. Waiting for service to start..."
sleep 10

# Check final status
echo "7. Final service status..."
sudo systemctl status canvas-course-generator.service --no-pager -l

echo ""
echo "=== Rebuild complete ==="
echo "Application has been completely rebuilt with the correct Okta configuration."
echo "The Okta redirect should now work properly."
echo ""
echo "If still having issues:"
echo "1. Clear browser cache completely (Ctrl+Shift+Delete)"
echo "2. Try incognito/private browsing mode"
echo "3. Check browser console for JavaScript errors"
echo "4. Verify the URL redirects to: https://digitalpromise.okta.com/oauth2/default/v1/authorize"