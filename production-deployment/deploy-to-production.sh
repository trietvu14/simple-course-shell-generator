#!/bin/bash

echo "=== Deploying to Production Server ==="

# Stop service
sudo systemctl stop canvas-course-generator.service

# Copy files
sudo cp -r . /home/ubuntu/canvas-course-generator/
sudo chown -R ubuntu:ubuntu /home/ubuntu/canvas-course-generator

# Install dependencies
cd /home/ubuntu/canvas-course-generator
npm install

# Install systemd service
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service

# Start service
sudo systemctl start canvas-course-generator.service

# Check status
sudo systemctl status canvas-course-generator.service

echo "Deployment complete!"
echo "Check logs with: sudo journalctl -u canvas-course-generator.service -f"
