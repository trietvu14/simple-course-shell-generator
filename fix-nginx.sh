#!/bin/bash

echo "Fixing nginx configuration for simple-course-shell-generator..."

# Ensure the public directory exists and has correct permissions
sudo mkdir -p /home/ubuntu/simple-course-shell-generator/public
sudo chown -R ubuntu:ubuntu /home/ubuntu/simple-course-shell-generator

# Create index.html if it doesn't exist
if [ ! -f "/home/ubuntu/simple-course-shell-generator/public/index.html" ]; then
    echo "Creating index.html..."
    cat > /home/ubuntu/simple-course-shell-generator/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canvas Course Shell Generator</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #f5f5f5;
            color: #333;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #e74c3c;
            font-size: 2.5rem;
            margin-bottom: 10px;
            text-align: center;
        }
        .status {
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .button {
            background: #e74c3c;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 4px;
            font-size: 16px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin: 10px 0;
        }
        .button:hover {
            background: #c0392b;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📚 Canvas Course Shell Generator</h1>
        <div class="status">
            <strong>Status:</strong> Server is running successfully!
        </div>
        <p>The Canvas Course Shell Generator is now active and ready to use.</p>
        <p>This application allows educational administrators to create multiple Canvas course shells efficiently.</p>
        <div style="text-align: center; margin-top: 30px;">
            <a href="/health" class="button">Check Health Status</a>
            <a href="/login" class="button">Login with Okta</a>
        </div>
    </div>
</body>
</html>
EOF
fi

# Set proper permissions for nginx to read the files
sudo chmod -R 755 /home/ubuntu/simple-course-shell-generator/public
sudo chown -R www-data:www-data /home/ubuntu/simple-course-shell-generator/public

# Create updated nginx configuration
echo "Creating nginx configuration..."
sudo tee /etc/nginx/sites-available/canvas-course-generator << 'EOF'
server {
    listen 80;
    server_name shell.dpvils.org;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name shell.dpvils.org;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/shell.dpvils.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/shell.dpvils.org/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Serve static files from public directory
    location / {
        root /home/ubuntu/simple-course-shell-generator/public;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # Allow nginx to read the files
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|html)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
    }

    # Proxy API routes and auth endpoints to Node.js
    location ~ ^/(api|login|logout|callback|health|test) {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        application/javascript
        application/json
        application/xml
        text/css
        text/javascript
        text/plain
        text/xml
        text/html;

    # File upload limits
    client_max_body_size 10M;
    
    # Logging
    access_log /var/log/nginx/canvas-course-generator.access.log;
    error_log /var/log/nginx/canvas-course-generator.error.log;
}
EOF

# Remove any existing symlink and create new one
sudo rm -f /etc/nginx/sites-enabled/canvas-course-generator
sudo ln -s /etc/nginx/sites-available/canvas-course-generator /etc/nginx/sites-enabled/

# Remove default nginx site if it exists
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
echo "Testing nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "Nginx configuration is valid. Reloading nginx..."
    sudo systemctl reload nginx
    echo "Nginx reloaded successfully!"
else
    echo "Nginx configuration test failed!"
    exit 1
fi

# Check file permissions
echo "Checking file permissions..."
ls -la /home/ubuntu/simple-course-shell-generator/
ls -la /home/ubuntu/simple-course-shell-generator/public/

echo ""
echo "Fix complete!"
echo "Test the application at: https://shell.dpvils.org"
echo "Check nginx logs: sudo tail -f /var/log/nginx/canvas-course-generator.error.log"