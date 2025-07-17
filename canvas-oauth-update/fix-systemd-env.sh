#!/bin/bash

echo "=== Fixing Systemd Service Environment Loading ==="

# Create a new systemd service file that properly loads .env file
cat > /etc/systemd/system/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator (React)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
Environment=PORT=5000
EnvironmentFile=/home/ubuntu/canvas-course-generator/.env
ExecStart=/usr/bin/node start-production.cjs
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Updated systemd service file to load .env file"

# Reload systemd and restart service
systemctl daemon-reload
systemctl restart canvas-course-generator.service

echo "Service restarted with environment file loading"

# Wait a moment for service to start
sleep 5

# Check service status
echo "=== Service Status ==="
systemctl status canvas-course-generator.service --no-pager

echo ""
echo "=== Recent Logs ==="
journalctl -u canvas-course-generator.service -n 10 --no-pager

echo ""
echo "=== Canvas OAuth Configuration Check ==="
echo "Look for 'Canvas OAuth initialized with config' in the logs."
echo "The clientId, canvasUrl, and redirectUri should now have proper values."