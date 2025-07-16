#!/bin/bash

echo "=== Canvas Course Shell Generator - Service Check ==="

# Check if service is running
echo "1. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager -l

echo ""
echo "2. Checking if application is responding..."
curl -s http://localhost:5000/health || echo "Health check failed"

echo ""
echo "3. Checking logs (last 20 lines)..."
sudo journalctl -u canvas-course-generator.service -n 20 --no-pager

echo ""
echo "4. Checking nginx status..."
sudo systemctl status nginx --no-pager -l

echo ""
echo "5. Testing nginx configuration..."
sudo nginx -t

echo ""
echo "6. Checking if port 5000 is listening..."
netstat -tulpn | grep :5000 || echo "Port 5000 not listening"

echo ""
echo "7. Checking environment variables..."
if [ -f "/home/ubuntu/canvas-course-generator/.env" ]; then
    echo "✓ .env file exists"
    grep -E "^(VITE_SIMPLE_AUTH|NODE_ENV|PORT)" /home/ubuntu/canvas-course-generator/.env
else
    echo "✗ .env file missing"
fi

echo ""
echo "8. Checking if simple auth is enabled..."
if [ -f "/home/ubuntu/canvas-course-generator/.env" ]; then
    if grep -q "VITE_SIMPLE_AUTH=true" /home/ubuntu/canvas-course-generator/.env; then
        echo "✓ Simple auth is enabled"
    else
        echo "✗ Simple auth is not enabled"
    fi
fi

echo ""
echo "=== Service Check Complete ==="
echo "If you're getting 403 errors, it's likely an nginx configuration issue."
echo "Try: sudo systemctl restart nginx"