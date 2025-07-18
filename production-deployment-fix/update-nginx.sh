#!/bin/bash

echo "=== Updating Nginx Configuration ==="

# Backup current nginx config
sudo cp /etc/nginx/sites-available/shell.dpvils.org /etc/nginx/sites-available/shell.dpvils.org.backup.$(date +%Y%m%d-%H%M%S)

# Copy new nginx config
sudo cp nginx-fix.conf /etc/nginx/sites-available/shell.dpvils.org

# Test nginx configuration
echo "Testing nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✓ Nginx configuration is valid"
    
    # Reload nginx
    echo "Reloading nginx..."
    sudo systemctl reload nginx
    
    echo "✓ Nginx configuration updated successfully"
else
    echo "✗ Nginx configuration is invalid"
    echo "Restoring backup..."
    sudo cp /etc/nginx/sites-available/shell.dpvils.org.backup.$(date +%Y%m%d-%H%M%S) /etc/nginx/sites-available/shell.dpvils.org
    exit 1
fi

echo ""
echo "=== Testing Configuration ==="
echo "Testing HTTPS redirect..."
curl -I http://shell.dpvils.org

echo ""
echo "Testing HTTPS connection..."
curl -I https://shell.dpvils.org

echo ""
echo "Testing API endpoint..."
curl -I https://shell.dpvils.org/api/health

echo ""
echo "Nginx configuration update complete!"
echo "The application should now be accessible at: https://shell.dpvils.org"