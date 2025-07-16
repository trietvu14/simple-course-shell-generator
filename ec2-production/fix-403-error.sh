#!/bin/bash

echo "=== Fixing 403 Forbidden Error ==="

# Set variables
APP_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Ensuring simple auth is enabled..."
cd "$APP_DIR"

# Make sure .env has VITE_SIMPLE_AUTH=true
if ! grep -q "VITE_SIMPLE_AUTH=true" .env; then
    echo "Adding VITE_SIMPLE_AUTH=true to .env..."
    echo "VITE_SIMPLE_AUTH=true" >> .env
fi

echo "2. Restarting the application service..."
sudo systemctl restart canvas-course-generator.service

echo "3. Waiting for service to start..."
sleep 5

echo "4. Checking if service is running..."
if sudo systemctl is-active --quiet canvas-course-generator.service; then
    echo "✓ Service is running"
else
    echo "✗ Service is not running"
    sudo systemctl status canvas-course-generator.service --no-pager -l
    exit 1
fi

echo "5. Testing local connection..."
curl -s http://localhost:5000 > /dev/null
if [ $? -eq 0 ]; then
    echo "✓ Local connection successful"
else
    echo "✗ Local connection failed"
fi

echo "6. Checking nginx configuration..."
sudo nginx -t

echo "7. Restarting nginx..."
sudo systemctl restart nginx

echo "8. Final test..."
sleep 3
curl -s -I http://localhost:5000 | head -n 1

echo ""
echo "=== Fix Complete ==="
echo "The application should now be accessible at https://shell.dpvils.org"
echo "Login with: admin / P@ssword01"
echo ""
echo "If you're still getting 403 errors, check:"
echo "1. Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "2. App logs: sudo journalctl -u canvas-course-generator.service -f"
echo "3. Service status: sudo systemctl status canvas-course-generator.service"