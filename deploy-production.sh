#!/bin/bash

# Canvas Course Shell Generator - Production Deployment Script
# Deploy to AWS EC2 at shell.dpvils.org

set -e

echo "🚀 Starting production deployment for Canvas Course Shell Generator"
echo "📍 Target: shell.dpvils.org"
echo "🔐 Authentication: Okta SSO + Simple Auth fallback"

# Check if running on EC2
if [ ! -f "/home/ubuntu" ]; then
    echo "❌ This script should be run on the EC2 instance"
    exit 1
fi

# Set production directory
PROD_DIR="/home/ubuntu/canvas-course-generator"
BACKUP_DIR="/home/ubuntu/canvas-course-generator-backup-$(date +%Y%m%d_%H%M%S)"

echo "📁 Production directory: $PROD_DIR"

# Create backup if existing deployment exists
if [ -d "$PROD_DIR" ]; then
    echo "📦 Creating backup of existing deployment..."
    cp -r "$PROD_DIR" "$BACKUP_DIR"
    echo "✅ Backup created at: $BACKUP_DIR"
fi

# Create production directory
mkdir -p "$PROD_DIR"
cd "$PROD_DIR"

echo "📥 Installing dependencies..."
npm install --production

echo "🏗️ Building application..."
npm run build

echo "🗄️ Setting up database..."
npm run db:push

echo "🔧 Configuring environment..."
# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Creating template..."
    cat > .env << 'EOF'
# Canvas Configuration
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=your_canvas_token

# Canvas OAuth (optional)
CANVAS_CLIENT_ID=280980000000000004
CANVAS_CLIENT_SECRET=your_canvas_oauth_secret
CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback

# Okta Authentication
OKTA_DOMAIN=digitalpromise.okta.com
OKTA_CLIENT_ID=your_okta_client_id
OKTA_CLIENT_SECRET=your_okta_client_secret
OKTA_REDIRECT_URI=https://shell.dpvils.org/callback
OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default

# Frontend Configuration
VITE_OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
VITE_OKTA_CLIENT_ID=your_okta_client_id
VITE_SIMPLE_AUTH=false

# Database
DATABASE_URL=postgresql://canvas_user:your_password@localhost:5432/canvas_course_generator

# Session Management
SESSION_SECRET=your_secure_session_secret
EOF
    echo "📝 Please update .env with your actual values"
fi

echo "🔄 Configuring systemd service..."
sudo tee /etc/systemd/system/canvas-course-generator.service > /dev/null << EOF
[Unit]
Description=Canvas Course Shell Generator
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$PROD_DIR
Environment=NODE_ENV=production
EnvironmentFile=$PROD_DIR/.env
ExecStart=/usr/bin/node server/index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "⚙️ Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator
sudo systemctl restart canvas-course-generator

echo "🔍 Checking service status..."
sudo systemctl status canvas-course-generator --no-pager

echo "🌐 Configuring Nginx..."
sudo tee /etc/nginx/sites-available/shell.dpvils.org > /dev/null << 'EOF'
server {
    listen 80;
    server_name shell.dpvils.org;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name shell.dpvils.org;
    
    ssl_certificate /etc/letsencrypt/live/shell.dpvils.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/shell.dpvils.org/privkey.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
}
EOF

# Enable nginx site
sudo ln -sf /etc/nginx/sites-available/shell.dpvils.org /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

echo "🎉 Production deployment completed!"
echo ""
echo "📋 Deployment Summary:"
echo "   🌍 URL: https://shell.dpvils.org"
echo "   🔐 Authentication: Okta SSO + Simple Auth"
echo "   📊 Canvas API: Integrated with fallback token"
echo "   🗄️ Database: PostgreSQL with migrations applied"
echo "   🔄 Process: systemd service running"
echo "   🌐 Web Server: Nginx with SSL/TLS"
echo ""
echo "🔍 To check logs:"
echo "   sudo journalctl -u canvas-course-generator -f"
echo ""
echo "🔧 To restart service:"
echo "   sudo systemctl restart canvas-course-generator"
echo ""
echo "✅ Canvas Course Shell Generator is now live at https://shell.dpvils.org"