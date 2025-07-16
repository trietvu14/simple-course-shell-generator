#!/bin/bash

echo "Deploying Canvas Course Shell Generator..."

# Ensure we're in the correct directory
cd /home/ubuntu/course-shell-generator

# Stop the current service if it exists
sudo systemctl stop canvas-course-generator 2>/dev/null || true

# Install dependencies for simplified version
echo "Installing dependencies..."
cp simple-package.json package.json
npm install

# Create .env file with production settings
echo "Creating .env file..."
cat > /home/ubuntu/course-shell-generator/.env << 'EOF'
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://canvas_app:DPVils25!@localhost:5432/canvas_course_generator
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7
OKTA_CLIENT_SECRET=Ez5CUFKEF2-MdAthRXS6EteDzs8sO28iUMDhHyFETDtIaVt1XufExidViy8uGGRz
OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
OKTA_REDIRECT_URI=https://shell.dpvils.org/callback
SESSION_SECRET=03fd8fb82564409ebe0c2678ff5c4fe9
EOF

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator
After=network.target
After=postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/course-shell-generator
ExecStart=/usr/bin/node simple-server.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
EnvironmentFile=/home/ubuntu/course-shell-generator/.env

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator
sudo systemctl start canvas-course-generator

# Check status
echo "Service status:"
sudo systemctl status canvas-course-generator --no-pager

echo ""
echo "Deployment complete!"
echo "Application is running at: https://shell.dpvils.org"
echo ""
echo "To check logs: sudo journalctl -u canvas-course-generator -f"
echo "To restart: sudo systemctl restart canvas-course-generator"