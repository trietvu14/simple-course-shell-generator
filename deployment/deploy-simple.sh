#!/bin/bash

echo "Deploying simplified Canvas Course Shell Generator..."

cd /home/ubuntu/course-shell-generator

# Stop the current service
sudo systemctl stop canvas-course-generator

# Backup current application
cp -r . ../course-shell-generator-backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

# Copy simplified files
cp simple-server.js app.js
cp simple-package.json package.json

# Create public directory if it doesn't exist
mkdir -p public

# Install dependencies
echo "Installing dependencies..."
npm install

# Update systemd service for simplified version
sudo tee /etc/systemd/system/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator (Simplified)
After=network.target
After=postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/course-shell-generator
ExecStart=/usr/bin/node app.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables
Environment=NODE_ENV=production
Environment=PORT=5000
Environment=DATABASE_URL=postgresql://canvas_app:DPVils25!@localhost:5432/canvas_course_generator
Environment=CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
Environment=CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
Environment=PGHOST=localhost
Environment=PGPORT=5432
Environment=PGUSER=canvas_app
Environment=PGPASSWORD=DPVils25!
Environment=PGDATABASE=canvas_course_generator
Environment=SESSION_SECRET=your-secret-key-change-this
Environment=OKTA_CLIENT_ID=your-okta-client-id
Environment=OKTA_CLIENT_SECRET=your-okta-client-secret
Environment=OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
Environment=OKTA_REDIRECT_URI=https://shell.dpvils.org/callback

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Start the service
sudo systemctl start canvas-course-generator

# Check status
sudo systemctl status canvas-course-generator --no-pager

echo "Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Update the Okta environment variables in the systemd service"
echo "2. Configure your Okta application with the redirect URI"
echo "3. Test the application at http://YOUR_EC2_IP:5000"