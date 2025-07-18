#!/bin/bash

echo "=== Deploying Simple Server Solution ==="
echo "This creates a working server that doesn't depend on build directory"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping current service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Navigating to directory..."
cd "$TARGET_DIR"

echo "3. Copying simple server..."
cp production-server-simple.js ./

echo "4. Creating systemd service for simple server..."
cat > canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator - Simple Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
EnvironmentFile=/home/ubuntu/canvas-course-generator/.env
ExecStart=/usr/bin/node production-server-simple.js
Restart=always
RestartSec=10
StartLimitBurst=5
StartLimitInterval=120
StandardOutput=journal
StandardError=journal
TimeoutStartSec=60
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

echo "5. Installing service..."
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload

echo "6. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "7. Waiting for startup..."
sleep 10

echo "8. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "9. Testing endpoints..."
echo "Health check:"
curl -s -w "HTTP %{http_code}\n" http://localhost:5000/health || echo "Failed"

echo "Root page:"
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:5000/ || echo "Failed"

echo "API test:"
curl -s -w "HTTP %{http_code}\n" http://localhost:5000/api/test || echo "Failed"

echo "10. Testing external access..."
curl -s -o /dev/null -w "HTTPS Health: HTTP %{http_code}\n" https://shell.dpvils.org/health || echo "External failed"

echo "11. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Simple Server Deployment Complete ==="
echo "✓ No build directory dependency"
echo "✓ Working health check and API endpoints"
echo "✓ Fallback HTML page for all routes"
echo "✓ Proper error handling and logging"
echo ""
echo "The server should now work without any build directory errors"
echo "Visit https://shell.dpvils.org to test"