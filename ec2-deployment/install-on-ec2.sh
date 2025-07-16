#!/bin/bash

echo "Installing React Canvas Course Shell Generator on EC2..."

# Stop existing service
sudo systemctl stop canvas-course-generator 2>/dev/null || true

# Backup existing installation
if [ -d "/home/ubuntu/canvas-course-generator" ]; then
    sudo mv /home/ubuntu/canvas-course-generator /home/ubuntu/canvas-course-generator.backup.$(date +%Y%m%d_%H%M%S)
fi

# Create installation directory
sudo mkdir -p /home/ubuntu/canvas-course-generator
sudo chown ubuntu:ubuntu /home/ubuntu/canvas-course-generator

# Copy all files
cp -r * /home/ubuntu/canvas-course-generator/

# Install dependencies
cd /home/ubuntu/canvas-course-generator
npm install

# Ensure Okta dependencies are installed
npm install @okta/okta-react @okta/okta-auth-js

# Update database schema
npm run db:push

# Create systemd service file
cat > canvas-course-generator.service << 'SYSTEMD_EOF'
[Unit]
Description=Canvas Course Shell Generator (React)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
ExecStart=/usr/bin/node production-server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

# Install and start service
sudo mv canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator
sudo systemctl start canvas-course-generator

# Check service status
sleep 5
sudo systemctl status canvas-course-generator

echo "Installation complete!"
echo "Service status:"
sudo systemctl is-active canvas-course-generator
echo "To view logs: sudo journalctl -u canvas-course-generator -f"
