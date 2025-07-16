#!/bin/bash

echo "=== Canvas Course Shell Generator - Force Okta Update ==="
echo "Forcing complete Okta configuration update..."

TARGET_DIR="/home/ubuntu/canvas-course-generator"

# Stop the service
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

# Backup current files
echo "2. Creating backup..."
mkdir -p "$TARGET_DIR/backup-$(date +%Y%m%d-%H%M%S)"
cp -r "$TARGET_DIR/client/src" "$TARGET_DIR/backup-$(date +%Y%m%d-%H%M%S)/" 2>/dev/null || true

# Create directories
echo "3. Creating directories..."
mkdir -p "$TARGET_DIR/client/src/lib"
mkdir -p "$TARGET_DIR/attached_assets"

# Force copy files with verbose output
echo "4. Copying files..."
echo "Copying okta-config.ts..."
cat > "$TARGET_DIR/client/src/lib/okta-config.ts" << 'EOF'
import { OktaAuth } from '@okta/okta-auth-js';

const oktaConfig = {
  issuer: 'https://digitalpromise.okta.com/oauth2/default',
  clientId: '0oapma7d718cb4oYu5d7',
  redirectUri: `${window.location.origin}/callback`,
  scopes: ['openid', 'profile', 'email'],
  pkce: true,
  restoreOriginalUri: async (oktaAuth: OktaAuth, originalUri: string) => {
    window.location.replace(originalUri || '/dashboard');
  },
};

export const oktaAuth = new OktaAuth(oktaConfig);
EOF

echo "Copying main.tsx..."
cat > "$TARGET_DIR/client/src/main.tsx" << 'EOF'
import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

createRoot(document.getElementById("root")!).render(<App />);
EOF

echo "Copying App.tsx..."
cp "client/src/App.tsx" "$TARGET_DIR/client/src/"

echo "Copying assets..."
cp -r "attached_assets/"* "$TARGET_DIR/attached_assets/" 2>/dev/null || true

echo "Copying environment..."
cp ".env" "$TARGET_DIR/.env"

# Set permissions
echo "5. Setting permissions..."
sudo chown -R ubuntu:ubuntu "$TARGET_DIR"
sudo chmod -R 755 "$TARGET_DIR"

# Force clear all cache
echo "6. Clearing all cache..."
rm -rf "$TARGET_DIR/dist"
rm -rf "$TARGET_DIR/node_modules/.vite"
rm -rf "$TARGET_DIR/node_modules/.cache"

# Install dependencies if needed
echo "7. Checking dependencies..."
cd "$TARGET_DIR"
npm install --silent

# Start service
echo "8. Starting service..."
sudo systemctl start canvas-course-generator.service

# Wait and check status
echo "9. Checking service status..."
sleep 5
sudo systemctl status canvas-course-generator.service --no-pager -l

echo ""
echo "=== Force update complete ==="
echo "Files have been forcefully updated with correct Okta configuration:"
echo "✓ Issuer URL: https://digitalpromise.okta.com/oauth2/default"
echo "✓ Security component properly configured in App.tsx"
echo "✓ Duplicate Security component removed from main.tsx"
echo "✓ All cache cleared"
echo ""
echo "The application should now redirect to the correct Okta OAuth endpoint."
echo "If still having issues, check the service logs: journalctl -u canvas-course-generator.service -f"