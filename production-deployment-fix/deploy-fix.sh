#!/bin/bash

echo "=== Deploying Fix to Production ==="

# Stop service
sudo systemctl stop canvas-course-generator.service

# Backup current deployment
sudo cp -r /home/ubuntu/canvas-course-generator /home/ubuntu/backup-$(date +%Y%m%d-%H%M%S)

# Copy new files
sudo cp -r . /home/ubuntu/canvas-course-generator/
sudo chown -R ubuntu:ubuntu /home/ubuntu/canvas-course-generator

# Go to target directory
cd /home/ubuntu/canvas-course-generator

# Install dependencies
npm install

# Build the application
npm run build

# Install systemd service
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service

# Start service
sudo systemctl start canvas-course-generator.service

# Check status
sudo systemctl status canvas-course-generator.service --no-pager

echo "Fix deployment complete!"
echo "Test at: https://shell.dpvils.org"
echo "Check logs: sudo journalctl -u canvas-course-generator.service -f"
