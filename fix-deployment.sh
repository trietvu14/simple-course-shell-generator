#!/bin/bash

echo "Fixing deployment issues..."

# Stop the service
sudo systemctl stop canvas-course-generator

# Ensure correct directory
cd /home/ubuntu/course-shell-generator

# Create the .env file directly
echo "Creating .env file..."
cat > .env << 'EOF'
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

# Ensure correct permissions
chown ubuntu:ubuntu .env
chmod 644 .env

# Verify the file exists
echo "Verifying .env file exists:"
ls -la .env

# Create a simplified systemd service that doesn't use EnvironmentFile
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

# Inline environment variables (more reliable than EnvironmentFile)
Environment=NODE_ENV=production
Environment=PORT=5000
Environment=DATABASE_URL=postgresql://canvas_app:DPVils25!@localhost:5432/canvas_course_generator
Environment=CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
Environment=CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
Environment=OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7
Environment=OKTA_CLIENT_SECRET=Ez5CUFKEF2-MdAthRXS6EteDzs8sO28iUMDhHyFETDtIaVt1XufExidViy8uGGRz
Environment=OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
Environment=OKTA_REDIRECT_URI=https://shell.dpvils.org/callback
Environment=SESSION_SECRET=03fd8fb82564409ebe0c2678ff5c4fe9

[Install]
WantedBy=multi-user.target
EOF

# Test that simple-server.js exists
echo "Verifying simple-server.js exists:"
ls -la simple-server.js

# Test Node.js can be found
echo "Testing Node.js:"
which node
node --version

# Reload systemd and start service
sudo systemctl daemon-reload
sudo systemctl start canvas-course-generator

echo "Service status:"
sudo systemctl status canvas-course-generator --no-pager

echo ""
echo "If service failed, check logs with:"
echo "sudo journalctl -u canvas-course-generator -f"