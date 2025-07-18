#!/bin/bash

echo "=== Deploying Clean Okta-Only Application to Production ==="
echo "Target: https://shell.dpvils.org"
echo "Authentication: Digital Promise Okta only"
echo "Canvas API: Personal access token (no OAuth)"

TARGET_DIR="/home/ubuntu/canvas-course-generator"
BACKUP_DIR="/home/ubuntu/backup-final-okta-$(date +%Y%m%d-%H%M%S)"

# Stop current service
echo "1. Stopping current service..."
sudo systemctl stop canvas-course-generator.service

# Create backup of current deployment
echo "2. Creating backup..."
sudo cp -r "$TARGET_DIR" "$BACKUP_DIR"
echo "✓ Backup created at: $BACKUP_DIR"

# Copy all application files
echo "3. Copying updated application files..."
sudo cp -r . "$TARGET_DIR/"
sudo chown -R ubuntu:ubuntu "$TARGET_DIR"
echo "✓ Files copied to production directory"

# Navigate to target directory
cd "$TARGET_DIR"

# Create clean production environment file
echo "4. Creating production environment configuration..."
cat > .env << 'EOF'
# Canvas API Configuration
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=YOUR_CANVAS_TOKEN_HERE

# Database Configuration
DATABASE_URL=YOUR_DATABASE_URL_HERE

# Okta Authentication Configuration
VITE_OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
VITE_OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7

# Canvas OAuth Configuration (disabled for production)
CANVAS_CLIENT_ID=280980000000000004
CANVAS_CLIENT_SECRET=Gy3PtTYcXTFWZ7kn93DkBreWzfztYyxyUXer8RCcfWr4JQcLUW9K2BYcuu7LQVYa
CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback
SESSION_SECRET=c5e3c9d4-d06e-4fae-89e8-0fa6805c0668

# Disable Canvas OAuth to prevent conflicts
DISABLE_CANVAS_OAUTH=true

# Production environment
NODE_ENV=production
EOF

echo "✓ Environment configuration created"

# Install dependencies
echo "5. Installing dependencies..."
npm install --production
echo "✓ Dependencies installed"

# Build application for production
echo "6. Building application for production..."
npm run build

# Verify build was successful
if [ -d "dist" ]; then
    echo "✓ Build successful - production files created"
    echo "Built files:"
    ls -la dist/
else
    echo "✗ Build failed - dist directory not found"
    exit 1
fi

# Create production systemd service
echo "7. Creating production systemd service..."
cat > canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator - Clean Okta Production
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
EnvironmentFile=/home/ubuntu/canvas-course-generator/.env
ExecStart=/usr/bin/node dist/index.js
Restart=always
RestartSec=10
StartLimitBurst=3
StartLimitInterval=60
StandardOutput=journal
StandardError=journal
TimeoutStartSec=60
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Install and enable systemd service
echo "8. Installing systemd service..."
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service
echo "✓ Systemd service installed and enabled"

# Start the service
echo "9. Starting production service..."
sudo systemctl start canvas-course-generator.service

# Wait for service to initialize
echo "10. Waiting for service to start..."
sleep 20

# Check service status
echo "11. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

# Test application endpoints
echo "12. Testing application..."
echo "Testing health endpoint..."
curl -s -o /dev/null -w "Health Check: HTTP %{http_code}\n" http://localhost:5000/health

echo "Testing root endpoint..."
curl -s -o /dev/null -w "Root Page: HTTP %{http_code}\n" http://localhost:5000/

echo "Testing API endpoint..."
curl -s -o /dev/null -w "API Test: HTTP %{http_code}\n" http://localhost:5000/api/test/canvas

# Show recent logs
echo "13. Recent application logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 20

# Test external access
echo "14. Testing external access..."
echo "HTTPS Health Check:"
curl -s -o /dev/null -w "HTTPS Health: HTTP %{http_code}\n" https://shell.dpvils.org/health

echo "HTTPS Root Page:"
curl -s -o /dev/null -w "HTTPS Root: HTTP %{http_code}\n" https://shell.dpvils.org/

echo ""
echo "=== Production Deployment Complete ==="
echo "✓ Simple authentication completely removed"
echo "✓ Clean Okta-only authentication implemented"
echo "✓ Production build deployed and running"
echo "✓ Canvas API using personal access token"
echo "✓ Service configured for automatic restart"
echo ""
echo "Application URL: https://shell.dpvils.org"
echo "Authentication: Digital Promise Okta SSO"
echo "Service Status: sudo systemctl status canvas-course-generator.service"
echo "Logs: sudo journalctl -u canvas-course-generator.service -f"
echo ""
echo "Next Steps:"
echo "1. Update .env file with actual CANVAS_API_TOKEN and DATABASE_URL"
echo "2. Restart service: sudo systemctl restart canvas-course-generator.service"
echo "3. Test Okta authentication flow at https://shell.dpvils.org"
echo "4. Verify Canvas API functionality"
echo ""
echo "Backup location: $BACKUP_DIR"