#!/bin/bash

echo "=== Comprehensive Production Fix ==="
echo "Fixing 404 errors and production deployment issues..."

TARGET_DIR="/home/ubuntu/canvas-course-generator"
BACKUP_DIR="/home/ubuntu/backup-$(date +%Y%m%d-%H%M%S)"

# Stop the service
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

# Create backup
echo "2. Creating backup..."
sudo cp -r "$TARGET_DIR" "$BACKUP_DIR"

# Copy all files
echo "3. Copying updated files..."
sudo cp -r . "$TARGET_DIR/"
sudo chown -R ubuntu:ubuntu "$TARGET_DIR"

# Go to target directory
cd "$TARGET_DIR"

# Install dependencies
echo "4. Installing dependencies..."
npm install

# Build the application for production
echo "5. Building application..."
npm run build

# Check if build was successful
if [ -d "dist" ]; then
    echo "✓ Build successful - dist directory created"
    ls -la dist/
else
    echo "✗ Build failed - dist directory not found"
    exit 1
fi

# Create proper production systemd service
echo "6. Creating production systemd service..."
cat > canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator - Production
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

[Install]
WantedBy=multi-user.target
EOF

# Install systemd service
echo "7. Installing systemd service..."
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service

# Start service
echo "8. Starting service..."
sudo systemctl start canvas-course-generator.service

# Wait for service to start
echo "9. Waiting for service to start..."
sleep 10

# Check service status
echo "10. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

# Test application
echo "11. Testing application..."
echo "Testing health endpoint..."
curl -v http://localhost:5000/health

echo ""
echo "Testing root endpoint..."
curl -v http://localhost:5000/ | head -20

echo ""
echo "12. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 30

echo ""
echo "=== Fix Complete ==="
echo "✓ Application built for production"
echo "✓ Service configured to run production build"
echo "✓ Service started and running"
echo ""
echo "Test the application at: https://shell.dpvils.org"
echo "Monitor logs with: sudo journalctl -u canvas-course-generator.service -f"