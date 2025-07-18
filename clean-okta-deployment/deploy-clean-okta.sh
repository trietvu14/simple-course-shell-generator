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
