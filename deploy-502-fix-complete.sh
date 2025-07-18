#!/bin/bash

echo "=== Deploying 502 Error Fix to Production ==="
echo "This will fix the module resolution issue causing the 502 Bad Gateway error"

# Production server details
PRODUCTION_SERVER="shell.dpvils.org"
TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping the failing service..."
sudo systemctl stop canvas-course-generator.service || echo "Service already stopped"

echo "2. Navigating to application directory..."
cd "$TARGET_DIR" || { echo "Directory not found"; exit 1; }

echo "3. Installing tsx globally for production..."
sudo npm install -g tsx

echo "4. Installing application dependencies..."
npm install

echo "5. Creating fixed systemd service configuration..."
cat > canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator - Fixed Production
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
EnvironmentFile=/home/ubuntu/canvas-course-generator/.env
ExecStart=/usr/bin/npx tsx server/index.ts
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

echo "6. Installing updated systemd service..."
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload

echo "7. Starting the fixed service..."
sudo systemctl start canvas-course-generator.service

echo "8. Waiting for service to initialize..."
sleep 15

echo "9. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "10. Testing local application..."
echo "Health check:"
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:5000/health || echo "Health check failed"

echo "Root endpoint:"
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:5000/ || echo "Root endpoint failed"

echo "11. Testing external HTTPS access..."
echo "External health check:"
curl -s -o /dev/null -w "HTTP %{http_code}\n" https://shell.dpvils.org/health || echo "External health check failed"

echo "External root page:"
curl -s -o /dev/null -w "HTTP %{http_code}\n" https://shell.dpvils.org/ || echo "External root page failed"

echo "12. Showing recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 15

echo ""
echo "=== 502 Error Fix Deployment Complete ==="
echo "✓ Service now uses tsx to run TypeScript directly"
echo "✓ Module resolution issues bypassed"
echo "✓ Production service configured with proper restart limits"
echo ""
echo "Application Status:"
echo "- Service: $(sudo systemctl is-active canvas-course-generator.service)"
echo "- Local Health: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health 2>/dev/null || echo 'Failed')"
echo "- External Access: $(curl -s -o /dev/null -w "%{http_code}" https://shell.dpvils.org/health 2>/dev/null || echo 'Failed')"
echo ""
echo "Next Steps:"
echo "1. Verify Okta authentication at https://shell.dpvils.org"
echo "2. Test Canvas API functionality after login"
echo "3. Monitor logs: sudo journalctl -u canvas-course-generator.service -f"
echo ""
echo "If issues persist, check environment variables in .env file"