#!/bin/bash

echo "Installing Canvas Course Shell Generator on EC2..."

# Stop existing service
sudo systemctl stop canvas-course-generator 2>/dev/null || true

# Backup existing installation
if [ -d "/home/ubuntu/canvas-course-generator" ]; then
    sudo mv /home/ubuntu/canvas-course-generator /home/ubuntu/canvas-course-generator.backup.$(date +%Y%m%d_%H%M%S)
fi

# Create installation directory
sudo mkdir -p /home/ubuntu/canvas-course-generator
sudo chown ubuntu:ubuntu /home/ubuntu/canvas-course-generator

# Copy all files to the new directory
cp -r * /home/ubuntu/canvas-course-generator/

# If old directory exists, preserve any custom configurations
if [ -d "/home/ubuntu/simple-course-shell-generator" ]; then
    echo "Found old installation directory, preserving configurations..."
    if [ -f "/home/ubuntu/simple-course-shell-generator/.env" ]; then
        echo "   Preserving existing .env file..."
        cp /home/ubuntu/simple-course-shell-generator/.env /home/ubuntu/canvas-course-generator/.env.backup
    fi
fi

# Install dependencies
cd /home/ubuntu/canvas-course-generator
npm install

# Use the working .env.simple file as the production .env
if [ -f .env.simple ]; then
    echo "Using .env.simple as production environment configuration..."
    cp .env.simple .env
    echo "✅ Production environment configured with working credentials"
else
    echo "⚠️  .env.simple not found, using existing .env or creating basic template..."
fi

# Update database schema
npm run db:push

# Make start script executable
chmod +x start-production.cjs

# Create systemd service file
sudo tee /etc/systemd/system/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator (React)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
ExecStart=/usr/bin/node start-production.cjs
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Install and start service
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