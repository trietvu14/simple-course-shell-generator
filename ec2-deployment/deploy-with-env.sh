#!/bin/bash

echo "🚀 Deploying Canvas Course Shell Generator with environment setup..."

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

# Check if .env file exists, if not create template
if [ ! -f .env ]; then
    echo "📝 Creating .env template..."
    cat > .env << 'ENV_EOF'
# Database Configuration
DATABASE_URL=postgresql://canvas_user:your_password@localhost:5432/canvas_db

# Canvas API Configuration
CANVAS_API_TOKEN=your_canvas_token_here
CANVAS_API_URL=https://canvas.instructure.com

# Okta Configuration
OKTA_CLIENT_ID=your_okta_client_id
OKTA_CLIENT_SECRET=your_okta_client_secret
OKTA_ISSUER=https://your-okta-domain.okta.com

# Application Configuration
PORT=5000
NODE_ENV=production
ENV_EOF
    
    echo "⚠️  IMPORTANT: You need to update the .env file with your actual credentials:"
    echo "   1. Edit: /home/ubuntu/canvas-course-generator/.env"
    echo "   2. Update DATABASE_URL with your PostgreSQL credentials"
    echo "   3. Update CANVAS_API_TOKEN with your Canvas API token"
    echo "   4. Update OKTA_* values with your Okta configuration"
    echo ""
    echo "💡 After updating .env, restart the service with:"
    echo "   sudo systemctl restart canvas-course-generator"
    echo ""
    read -p "Press Enter to continue with deployment (you can update .env later)..."
else
    echo "✅ .env file already exists, using existing configuration"
fi

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
EnvironmentFile=/home/ubuntu/canvas-course-generator/.env

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator

# Try to push database schema (will fail if DATABASE_URL is not set)
echo "🗄️  Attempting to update database schema..."
if npm run db:push; then
    echo "✅ Database schema updated successfully"
else
    echo "⚠️  Database schema update failed - this is expected if DATABASE_URL is not configured"
    echo "   Update your .env file and run: npm run db:push"
fi

# Start the service
sudo systemctl start canvas-course-generator

# Check service status
sleep 3
echo ""
echo "🔍 Service Status:"
sudo systemctl status canvas-course-generator --no-pager

echo ""
echo "📊 Service Activity:"
if sudo systemctl is-active --quiet canvas-course-generator; then
    echo "✅ Service is running"
else
    echo "❌ Service is not running - check logs:"
    echo "   sudo journalctl -u canvas-course-generator -f"
fi

echo ""
echo "🎯 Deployment Summary:"
echo "   • React application installed"
echo "   • SystemD service configured"
echo "   • Environment file created/verified"
echo "   • Service started"
echo ""
echo "📋 Next Steps:"
echo "   1. Update /home/ubuntu/canvas-course-generator/.env with your credentials"
echo "   2. Run: sudo systemctl restart canvas-course-generator"
echo "   3. Check logs: sudo journalctl -u canvas-course-generator -f"
echo "   4. Test: https://shell.dpvils.org"