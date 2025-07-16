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

# Copy all files
cp -r * /home/ubuntu/canvas-course-generator/

# Install dependencies
cd /home/ubuntu/canvas-course-generator
npm install

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << 'ENV_EOF'
DATABASE_URL=postgresql://canvas_user:your_password@localhost:5432/canvas_db
CANVAS_API_TOKEN=your_canvas_token
CANVAS_API_URL=https://canvas.instructure.com
OKTA_CLIENT_ID=your_okta_client_id
OKTA_CLIENT_SECRET=your_okta_client_secret
OKTA_ISSUER=https://your-okta-domain.okta.com
ENV_EOF
    echo "⚠️  IMPORTANT: Update the .env file with your actual database and API credentials"
    echo "   Edit: /home/ubuntu/canvas-course-generator/.env"
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