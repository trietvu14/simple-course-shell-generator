#!/bin/bash

echo "=== Fixing TSX Issue for Production ==="

APP_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Installing tsx globally..."
sudo npm install -g tsx

echo "2. Checking tsx installation..."
which tsx
tsx --version

echo "3. Installing local dependencies..."
cd "$APP_DIR"
sudo npm install

echo "4. Testing tsx with server file..."
sudo -u ubuntu tsx server/index.ts --help

echo "5. Restarting service..."
sudo systemctl restart canvas-course-generator.service

echo "6. Checking service status..."
sleep 5
if sudo systemctl is-active --quiet canvas-course-generator.service; then
    echo "✅ Service is now running!"
else
    echo "❌ Service still not running. Checking logs..."
    sudo journalctl -u canvas-course-generator.service -n 10 --no-pager
fi

echo "7. Testing application..."
curl -s -f http://localhost:5000/health && echo "✅ Application responding!" || echo "❌ Application not responding"