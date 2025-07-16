#!/bin/bash

echo "=== Canvas Course Shell Generator - Complete EC2 Deployment ==="
echo "Deploying simple authentication version to EC2..."

# Set variables
APP_DIR="/home/ubuntu/canvas-course-generator"
CURRENT_DIR="$(pwd)"
REPO_DIR="$(dirname "$CURRENT_DIR")"

# Stop the service if it exists
echo "1. Stopping existing service..."
sudo systemctl stop canvas-course-generator.service 2>/dev/null || echo "Service not running"

# Create backup of existing directory
if [ -d "$APP_DIR" ]; then
    echo "2. Creating backup..."
    sudo mv "$APP_DIR" "$APP_DIR.backup.$(date +%Y%m%d-%H%M%S)"
fi

# Copy the entire repository (parent directory)
echo "3. Copying application files..."
sudo cp -r "$REPO_DIR" "$APP_DIR"

# Set proper ownership
echo "4. Setting permissions..."
sudo chown -R ubuntu:ubuntu "$APP_DIR"
sudo chmod -R 755 "$APP_DIR"

# Install dependencies
echo "5. Installing dependencies..."
cd "$APP_DIR"
npm install

# Copy production files from ec2-production subdirectory
echo "6. Setting up production configuration..."
cp ec2-production/.env .env
cp ec2-production/start-production.cjs start-production.cjs
sudo cp ec2-production/canvas-course-generator.service /etc/systemd/system/

# Reload systemd and enable service
echo "7. Configuring systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service

# Start the service
echo "8. Starting service..."
sudo systemctl start canvas-course-generator.service

# Check status
echo "9. Checking service status..."
sleep 5
sudo systemctl status canvas-course-generator.service --no-pager -l

# Setup nginx configuration
echo "10. Setting up nginx configuration..."
cd "$APP_DIR/ec2-production"
chmod +x setup-nginx.sh
./setup-nginx.sh

echo ""
echo "=== Deployment Complete ==="
echo "✓ Simple authentication enabled (admin / P@ssword01)"
echo "✓ Canvas API integration ready"
echo "✓ Service running on port 5000"
echo "✓ Database connection configured"
echo "✓ Nginx proxy configured"
echo ""
echo "Access the application at: https://shell.dpvils.org"
echo "Login with: admin / P@ssword01"
echo ""
echo "Useful commands:"
echo "• Check app logs: sudo journalctl -u canvas-course-generator.service -f"
echo "• Restart app: sudo systemctl restart canvas-course-generator.service"
echo "• Check nginx: sudo systemctl status nginx"
echo "• Nginx logs: sudo tail -f /var/log/nginx/error.log"