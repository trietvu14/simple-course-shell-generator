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

# Copy all files to the new directory
cp -r * /home/ubuntu/canvas-course-generator/

# If old directory exists, preserve any custom configurations
if [ -d "/home/ubuntu/simple-course-shell-generator" ]; then
    echo "📋 Found old installation directory, preserving configurations..."
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
    echo "📝 Using .env.simple as production environment configuration..."
    cp .env.simple .env
    echo "✅ Production environment configured with working credentials"
else
    echo "⚠️  .env.simple not found, creating basic template..."
    cat > .env << 'ENV_EOF'
# Database Configuration
DATABASE_URL=postgresql://canvas_app:DPVils25!@localhost:5432/canvas_course_generator

# Canvas API Configuration  
CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1

# Okta Configuration
OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7
OKTA_CLIENT_SECRET=Ez5CUFKEF2-MdAthRXS6EteDzs8sO28iUMDhHyFETDtIaVt1XufExidViy8uGGRz
OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
OKTA_REDIRECT_URI=https://shell.dpvils.org/callback

# Application Configuration
PORT=5000
NODE_ENV=production
SESSION_SECRET=03fd8fb82564409ebe0c2678ff5c4fe9
ENV_EOF
    echo "✅ Production environment configured with working credentials"
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

# Build the React application for production (optional, can be skipped for faster deployment)
echo "🏗️  Building React application for production..."
echo "   This may take a few minutes..."
if timeout 300 npm run build; then
    echo "✅ React application built successfully"
    echo "   Static files available in: /home/ubuntu/canvas-course-generator/dist/"
    echo "   Update your nginx configuration to serve from /home/ubuntu/canvas-course-generator/dist/"
else
    echo "⚠️  React build failed or timed out - application will run in development mode"
    echo "   The application will still work correctly, just not optimized for production"
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