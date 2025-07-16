#!/bin/bash

echo "=== Canvas Course Shell Generator - Okta Fix Deployment ==="
echo "Deploying Okta authentication fix..."

# Set target directory
TARGET_DIR="/home/ubuntu/canvas-course-generator"

# Stop the service first
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

# Create target directories if they don't exist
echo "2. Creating directories..."
mkdir -p "$TARGET_DIR/client/src/lib"
mkdir -p "$TARGET_DIR/client/src/pages"
mkdir -p "$TARGET_DIR/attached_assets"

# Copy the fixed files
echo "3. Copying fixed files..."
cp client/src/lib/okta-config.ts "$TARGET_DIR/client/src/lib/"
cp client/src/App.tsx "$TARGET_DIR/client/src/"
cp client/src/main.tsx "$TARGET_DIR/client/src/"
cp -r attached_assets/* "$TARGET_DIR/attached_assets/"

# Set permissions
echo "4. Setting permissions..."
sudo chown -R ubuntu:ubuntu "$TARGET_DIR"
sudo chmod -R 755 "$TARGET_DIR"

# Clear any build cache
echo "5. Clearing build cache..."
rm -rf "$TARGET_DIR/dist"
rm -rf "$TARGET_DIR/node_modules/.vite"

# Copy environment file
echo "6. Copying environment..."
cp .env "$TARGET_DIR/.env"

# Start the service
echo "7. Starting service..."
sudo systemctl start canvas-course-generator.service

# Check status
echo "8. Checking service status..."
sleep 3
sudo systemctl status canvas-course-generator.service --no-pager -l

echo ""
echo "=== Deployment complete ==="
echo "Key changes made:"
echo "✓ Fixed Okta issuer URL to: https://digitalpromise.okta.com/oauth2/default"
echo "✓ Removed duplicate Security component from main.tsx"
echo "✓ Properly configured Security component in App.tsx"
echo "✓ Added Canvas logo assets"
echo "✓ Cleared build cache"
echo ""
echo "The application should now properly redirect to the Okta OAuth endpoint."
echo "URL should be: https://digitalpromise.okta.com/oauth2/default/v1/authorize"
echo "If the issue persists, clear your browser cache and try a hard refresh (Ctrl+F5)."