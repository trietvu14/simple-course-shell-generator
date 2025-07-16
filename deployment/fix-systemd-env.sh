#!/bin/bash

echo "Fixing systemd service to load .env file properly..."

# Update the systemd service file to use EnvironmentFile
sudo tee /etc/systemd/system/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator
After=network.target
After=postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/course-shell-generator
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Load environment variables from .env file
EnvironmentFile=/home/ubuntu/course-shell-generator/.env

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd configuration..."
sudo systemctl daemon-reload

echo "Restarting canvas-course-generator service..."
sudo systemctl restart canvas-course-generator

echo "Checking service status..."
sudo systemctl status canvas-course-generator --no-pager

echo "Testing health endpoint..."
sleep 2
curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health

echo "Service update complete!"