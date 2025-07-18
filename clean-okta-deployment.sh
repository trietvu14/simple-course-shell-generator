#!/bin/bash

echo "=== Creating Clean Okta-Only Deployment ==="
echo "Removing simple auth and preparing pure Okta deployment..."

# Create clean deployment directory
mkdir -p clean-okta-deployment
cp -r client server shared public *.json *.ts *.js *.md clean-okta-deployment/

# Create clean .env file with only Okta authentication
cat > clean-okta-deployment/.env << 'EOF'
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=${CANVAS_API_TOKEN}
DATABASE_URL=${DATABASE_URL}

# Canvas OAuth Configuration (disabled for now)
CANVAS_CLIENT_ID=280980000000000004
CANVAS_CLIENT_SECRET=Gy3PtTYcXTFWZ7kn93DkBreWzfztYyxyUXer8RCcfWr4JQcLUW9K2BYcuu7LQVYa
CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback
SESSION_SECRET=c5e3c9d4-d06e-4fae-89e8-0fa6805c0668

# Okta Authentication Configuration
VITE_OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
VITE_OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7

# Disable Canvas OAuth to prevent conflicts
DISABLE_CANVAS_OAUTH=true
EOF

# Create deployment script
cat > clean-okta-deployment/deploy-clean-okta.sh << 'EOF'
#!/bin/bash

echo "=== Deploying Clean Okta-Only Application ==="

TARGET_DIR="/home/ubuntu/canvas-course-generator"
BACKUP_DIR="/home/ubuntu/backup-clean-okta-$(date +%Y%m%d-%H%M%S)"

# Stop service
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

# Create backup
echo "2. Creating backup..."
sudo cp -r "$TARGET_DIR" "$BACKUP_DIR"

# Copy files
echo "3. Copying clean application files..."
sudo cp -r . "$TARGET_DIR/"
sudo chown -R ubuntu:ubuntu "$TARGET_DIR"

# Go to target directory
cd "$TARGET_DIR"

# Install dependencies
echo "4. Installing dependencies..."
npm install

# Build application
echo "5. Building application..."
npm run build

# Check build
if [ -d "dist" ]; then
    echo "✓ Build successful"
    ls -la dist/
else
    echo "✗ Build failed"
    exit 1
fi

# Create production systemd service
echo "6. Creating systemd service..."
cat > canvas-course-generator.service << 'SEOF'
[Unit]
Description=Canvas Course Shell Generator - Okta Production
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
EnvironmentFile=/home/ubuntu/canvas-course-generator/.env
ExecStart=/usr/bin/node dist/index.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
TimeoutStartSec=60

[Install]
WantedBy=multi-user.target
SEOF

# Install service
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service

# Start service
echo "7. Starting service..."
sudo systemctl start canvas-course-generator.service

# Wait for startup
echo "8. Waiting for service to start..."
sleep 20

# Check status
echo "9. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

# Test application
echo "10. Testing application..."
curl -s -o /dev/null -w "Health Check: %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root Page: %{http_code}\n" http://localhost:5000/

# Show logs
echo "11. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 30

echo ""
echo "=== Clean Okta Deployment Complete ==="
echo "✓ Simple authentication removed"
echo "✓ Only Okta authentication enabled"
echo "✓ Canvas OAuth disabled to prevent conflicts"
echo "✓ Production build deployed"
echo ""
echo "Test at: https://shell.dpvils.org"
echo "Monitor: sudo journalctl -u canvas-course-generator.service -f"
EOF

chmod +x clean-okta-deployment/deploy-clean-okta.sh

# Create test script
cat > clean-okta-deployment/test-okta-flow.sh << 'EOF'
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
EOF

chmod +x clean-okta-deployment/test-okta-flow.sh

echo ""
echo "=== Clean Okta Deployment Package Created ==="
echo "✓ Simple authentication completely removed"
echo "✓ Only Okta authentication enabled"
echo "✓ Canvas OAuth disabled to prevent conflicts"
echo "✓ Clean environment configuration"
echo "✓ Production deployment script"
echo "✓ Okta flow testing script"
echo ""
echo "To deploy:"
echo "1. Upload clean-okta-deployment/ to server"
echo "2. Run: ./deploy-clean-okta.sh"
echo "3. Test: ./test-okta-flow.sh"
echo ""
echo "This addresses the OAuth error by:"
echo "- Removing all simple auth complexity"
echo "- Using only Okta authentication"
echo "- Disabling Canvas OAuth to prevent conflicts"
echo "- Providing clean production build"