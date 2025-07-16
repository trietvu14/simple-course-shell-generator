#!/bin/bash

echo "=== Canvas Course Shell Generator - Fix Deployment Issues ==="

# Stop the service
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service 2>/dev/null || echo "Service not running"

# Remove old service file
echo "2. Removing old service configuration..."
sudo rm -f /etc/systemd/system/canvas-course-generator.service

# Set correct paths
APP_DIR="/home/ubuntu/canvas-course-generator"
echo "3. Checking application directory: $APP_DIR"

if [ ! -d "$APP_DIR" ]; then
    echo "ERROR: Application directory does not exist: $APP_DIR"
    echo "Please ensure the repository is copied to the correct location."
    exit 1
fi

# Navigate to app directory
cd "$APP_DIR"

# Ensure production files exist
echo "4. Checking production files..."
if [ ! -f "ec2-production/.env" ]; then
    echo "ERROR: ec2-production/.env not found"
    exit 1
fi

if [ ! -f "ec2-production/start-production.cjs" ]; then
    echo "ERROR: ec2-production/start-production.cjs not found"
    exit 1
fi

if [ ! -f "ec2-production/canvas-course-generator.service" ]; then
    echo "ERROR: ec2-production/canvas-course-generator.service not found"
    exit 1
fi

# Copy production files
echo "5. Setting up production configuration..."
cp ec2-production/.env .env
cp ec2-production/start-production.cjs start-production.cjs
sudo cp ec2-production/canvas-course-generator.service /etc/systemd/system/

# Set proper permissions
echo "6. Setting permissions..."
sudo chown -R ubuntu:ubuntu "$APP_DIR"
chmod +x start-production.cjs
sudo chmod 644 /etc/systemd/system/canvas-course-generator.service

# Install dependencies if needed
echo "7. Installing dependencies..."
npm install

# Reload systemd and enable service
echo "8. Configuring systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service

# Start the service
echo "9. Starting service..."
sudo systemctl start canvas-course-generator.service

# Wait and check status
echo "10. Checking service status..."
sleep 5
sudo systemctl status canvas-course-generator.service --no-pager -l

# Check if service is running
if sudo systemctl is-active --quiet canvas-course-generator.service; then
    echo "✓ Service is running successfully"
else
    echo "✗ Service failed to start"
    echo "Checking logs..."
    sudo journalctl -u canvas-course-generator.service --no-pager -l
fi

echo ""
echo "=== Fix Deployment Complete ==="
echo "If the service is running, access the application at: https://shell.dpvils.org"
echo "Login with: admin / P@ssword01"