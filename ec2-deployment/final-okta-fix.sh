#!/bin/bash

echo "=== Canvas Course Shell Generator - Final Okta Fix ==="
echo "Applying definitive fix for Okta authentication redirect..."

TARGET_DIR="/home/ubuntu/canvas-course-generator"

# Stop the service
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

# Force overwrite the problematic files
echo "2. Overwriting configuration files..."

# Create the correct okta-config.ts with environment variable support
cat > "$TARGET_DIR/client/src/lib/okta-config.ts" << 'EOF'
import { OktaAuth } from '@okta/okta-auth-js';

const oktaConfig = {
  issuer: import.meta.env.VITE_OKTA_ISSUER || 'https://digitalpromise.okta.com/oauth2/default',
  clientId: import.meta.env.VITE_OKTA_CLIENT_ID || '0oapma7d718cb4oYu5d7',
  redirectUri: `${window.location.origin}/callback`,
  scopes: ['openid', 'profile', 'email'],
  pkce: true,
  restoreOriginalUri: async (oktaAuth: OktaAuth, originalUri: string) => {
    window.location.replace(originalUri || '/dashboard');
  },
};

export const oktaAuth = new OktaAuth(oktaConfig);
EOF

# Update the .env file with complete configuration
cp ".env" "$TARGET_DIR/.env"

# Set permissions
echo "3. Setting permissions..."
sudo chown -R ubuntu:ubuntu "$TARGET_DIR"
sudo chmod -R 755 "$TARGET_DIR"

# Clear all possible caches
echo "4. Clearing all caches..."
cd "$TARGET_DIR"
rm -rf dist/
rm -rf node_modules/.vite/
rm -rf node_modules/.cache/
rm -rf .vite/

# Start the service
echo "5. Starting service..."
sudo systemctl start canvas-course-generator.service

# Wait for service to start
echo "6. Waiting for service to start..."
sleep 10

# Show final status
echo "7. Final service status..."
sudo systemctl status canvas-course-generator.service --no-pager -l

echo ""
echo "=== Final Okta Fix Complete ==="
echo "Configuration applied:"
echo "✓ Client-side Okta config uses environment variables"
echo "✓ VITE_OKTA_ISSUER = https://digitalpromise.okta.com/oauth2/default"
echo "✓ VITE_OKTA_CLIENT_ID = 0oapma7d718cb4oYu5d7"
echo "✓ All caches cleared"
echo "✓ Service restarted"
echo ""
echo "The application should now redirect to the correct Okta OAuth endpoint."
echo "Test URL: https://shell.dpvils.org"
echo "Expected redirect: https://digitalpromise.okta.com/oauth2/default/v1/authorize"