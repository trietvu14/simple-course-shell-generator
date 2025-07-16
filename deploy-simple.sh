#!/bin/bash

echo "Deploying simplified Canvas Course Shell Generator..."

# Stop any existing services
sudo systemctl stop canvas-course-generator 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

# Create deployment directory
sudo mkdir -p /home/ubuntu/simple-course-shell-generator
cd /home/ubuntu/simple-course-shell-generator

# Copy files
sudo cp /home/runner/simple-course-shell-generator/simple-server.js .
sudo cp /home/runner/simple-course-shell-generator/simple-package.json ./package.json
sudo cp /home/runner/simple-course-shell-generator/.env.simple ./.env

# Update package.json for deployment
cat > package.json << 'EOF'
{
  "name": "canvas-course-generator",
  "version": "1.0.0",
  "description": "Canvas Course Shell Generator",
  "main": "simple-server.js",
  "scripts": {
    "start": "node simple-server.js",
    "dev": "node simple-server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "express-session": "^1.17.3",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1"
  }
}
EOF

# Install dependencies
sudo npm install --production

# Create updated .env file with current secrets
cat > .env << EOF
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://canvas_app:DPVils25!@localhost:5432/canvas_course_generator
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=${CANVAS_API_TOKEN}
OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7
OKTA_CLIENT_SECRET=Ez5CUFKEF2-MdAthRXS6EteDzs8sO28iUMDhHyFETDtIaVt1XufExidViy8uGGRz
OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
OKTA_REDIRECT_URI=https://shell.dpvils.org/callback
SESSION_SECRET=03fd8fb82564409ebe0c2678ff5c4fe9
EOF

# Copy the updated public/index.html
sudo mkdir -p public
sudo cp /home/runner/simple-course-shell-generator/public/index.html ./public/

# Set proper permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/simple-course-shell-generator
sudo chmod -R 755 /home/ubuntu/simple-course-shell-generator
sudo chmod 644 /home/ubuntu/simple-course-shell-generator/public/index.html

# Create systemd service
sudo tee /etc/systemd/system/canvas-course-generator.service > /dev/null << 'EOF'
[Unit]
Description=Canvas Course Shell Generator
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/simple-course-shell-generator
Environment=NODE_ENV=production
ExecStart=/usr/bin/node simple-server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=canvas-course-generator

[Install]
WantedBy=multi-user.target
EOF

# Update nginx configuration
sudo tee /etc/nginx/sites-available/canvas-course-generator > /dev/null << 'EOF'
server {
    listen 80;
    server_name shell.dpvils.org;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name shell.dpvils.org;

    ssl_certificate /etc/letsencrypt/live/shell.dpvils.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/shell.dpvils.org/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /home/ubuntu/simple-course-shell-generator/public;
    index index.html;

    # API routes proxy to Node.js
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Auth routes proxy to Node.js
    location ~ ^/(login|logout|callback|health)$ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Static files
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    error_log /var/log/nginx/canvas-course-generator.error.log;
    access_log /var/log/nginx/canvas-course-generator.access.log;
}
EOF

# Enable and restart services
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator
sudo systemctl start canvas-course-generator

# Test service
sleep 3
if systemctl is-active --quiet canvas-course-generator; then
    echo "✓ Canvas Course Generator service is running"
else
    echo "✗ Canvas Course Generator service failed to start"
    sudo systemctl status canvas-course-generator
fi

# Restart nginx
sudo systemctl restart nginx

echo ""
echo "Deployment complete!"
echo "Application URL: https://shell.dpvils.org"
echo "Health check: https://shell.dpvils.org/health"
echo ""
echo "Check status with:"
echo "  sudo systemctl status canvas-course-generator"
echo "  sudo journalctl -u canvas-course-generator -f"