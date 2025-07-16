#!/bin/bash

echo "Fixing missing dependencies and rebuilding application..."

cd /home/ubuntu/course-shell-generator

# Stop the service first
echo "1. Stopping application service..."
sudo systemctl stop canvas-course-generator

# Clean up node_modules and package-lock.json
echo "2. Cleaning up existing node_modules..."
rm -rf node_modules/
rm -f package-lock.json

# Install dependencies
echo "3. Installing dependencies..."
npm install

# Verify express is installed
echo "4. Verifying Express installation..."
ls -la node_modules/express/ || echo "Express not found in node_modules"

# Build the application
echo "5. Building application..."
npm run build

# Check if dist/index.js exists
echo "6. Checking build output..."
ls -la dist/index.js || echo "Build output not found"

# Start the service
echo "7. Starting application service..."
sudo systemctl start canvas-course-generator

# Check service status
echo "8. Checking service status..."
sudo systemctl status canvas-course-generator --no-pager

# Wait for startup
sleep 5

# Check logs
echo "9. Checking recent logs..."
sudo journalctl -u canvas-course-generator -n 10 --no-pager

# Test health endpoint
echo "10. Testing health endpoint..."
curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health

echo "Dependencies fix complete!"