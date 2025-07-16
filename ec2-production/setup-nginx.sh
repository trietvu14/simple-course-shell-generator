#!/bin/bash

echo "=== Setting up Nginx for Canvas Course Shell Generator ==="

# Variables
DOMAIN="shell.dpvils.org"
NGINX_SITE="/etc/nginx/sites-available/canvas-course-generator"
NGINX_ENABLED="/etc/nginx/sites-enabled/canvas-course-generator"

# Remove default nginx site
echo "1. Removing default nginx configuration..."
sudo rm -f /etc/nginx/sites-enabled/default

# Copy our nginx configuration
echo "2. Installing nginx site configuration..."
sudo cp nginx-site.conf "$NGINX_SITE"

# Enable the site
echo "3. Enabling the site..."
sudo ln -sf "$NGINX_SITE" "$NGINX_ENABLED"

# Test nginx configuration
echo "4. Testing nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "5. Reloading nginx..."
    sudo systemctl reload nginx
    echo "✓ Nginx configuration updated successfully"
else
    echo "✗ Nginx configuration test failed"
    exit 1
fi

# Check if SSL certificates exist
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "✓ SSL certificates found"
else
    echo "⚠ SSL certificates not found"
    echo "To set up SSL certificates, run:"
    echo "sudo certbot --nginx -d $DOMAIN"
fi

echo ""
echo "=== Nginx Setup Complete ==="
echo "Your application should now be accessible at:"
echo "• HTTP: http://$DOMAIN (redirects to HTTPS)"
echo "• HTTPS: https://$DOMAIN"
echo ""
echo "To check nginx status: sudo systemctl status nginx"
echo "To view nginx logs: sudo tail -f /var/log/nginx/error.log"