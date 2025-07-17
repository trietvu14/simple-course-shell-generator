#!/bin/bash

echo "=== Canvas OAuth Production Environment Check ==="
echo ""

# Check if .env file exists
if [ -f "/home/ubuntu/canvas-course-generator/.env" ]; then
    echo "✅ .env file exists"
    echo ""
    echo "Canvas OAuth variables in .env:"
    grep -E "(CANVAS_CLIENT_ID|CANVAS_CLIENT_SECRET|CANVAS_REDIRECT_URI|CANVAS_API_URL|SESSION_SECRET)" /home/ubuntu/canvas-course-generator/.env
else
    echo "❌ .env file not found at /home/ubuntu/canvas-course-generator/.env"
    echo ""
    echo "Expected location: /home/ubuntu/canvas-course-generator/.env"
    echo "Please create the .env file with the Canvas OAuth variables."
fi

echo ""
echo "=== Required Variables ==="
echo "CANVAS_CLIENT_ID=280980000000000004"
echo "CANVAS_CLIENT_SECRET=Gy3PtTYcXTFWZ7kn93DkBreWzfztYyxyUXer8RCcfWr4JQcLUW9K2BYcuu7LQVYa"
echo "CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback"
echo "CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1"
echo "SESSION_SECRET=c5e3c9d4-d06e-4fae-89e8-0fa6805c0668"
echo ""

# Check if service can access environment variables
echo "=== Service Environment Test ==="
echo "Checking if systemd service can access environment variables..."
sudo systemctl show canvas-course-generator.service --property=Environment
echo ""

echo "=== Service Status ==="
sudo systemctl status canvas-course-generator.service --no-pager
echo ""

echo "=== Recent Service Logs ==="
sudo journalctl -u canvas-course-generator.service -n 10 --no-pager
echo ""

echo "=== Canvas OAuth Configuration Test ==="
echo "Look for 'Canvas OAuth initialized with config' in the logs above."
echo "If you see empty values, the environment variables are not being loaded properly."