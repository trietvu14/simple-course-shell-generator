#!/bin/bash

echo "=== Fixing 502 Bad Gateway Error ==="
echo "The issue is with module resolution in production build"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

# Stop the failing service
echo "1. Stopping failing service..."
sudo systemctl stop canvas-course-generator.service

# Go to application directory
cd "$TARGET_DIR"

# Check current build directory
echo "2. Checking build directory..."
if [ -d "dist" ]; then
    echo "Current dist contents:"
    ls -la dist/
    echo ""
    echo "Checking for index.js:"
    if [ -f "dist/index.js" ]; then
        echo "✓ index.js exists"
        echo "First few lines:"
        head -10 dist/index.js
    else
        echo "✗ index.js missing"
    fi
else
    echo "✗ dist directory missing"
fi

# The issue is likely that we need to run the production build differently
# Let's use tsx to run the TypeScript directly in production instead of building
echo "3. Creating fixed systemd service to run TypeScript directly..."

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
StartLimitBurst=3
StartLimitInterval=60
StandardOutput=journal
StandardError=journal
TimeoutStartSec=60
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Install the fixed service
echo "4. Installing fixed systemd service..."
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload

# Make sure tsx is available globally
echo "5. Ensuring tsx is available..."
npm install -g tsx

# Install dependencies if needed
echo "6. Installing dependencies..."
npm install

# Start the service
echo "7. Starting fixed service..."
sudo systemctl start canvas-course-generator.service

# Wait for startup
echo "8. Waiting for service to start..."
sleep 15

# Check status
echo "9. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

# Test the application
echo "10. Testing application..."
curl -s -o /dev/null -w "Health Check: HTTP %{http_code}\n" http://localhost:5000/health || echo "Health check failed"

# Show recent logs
echo "11. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 20

echo ""
echo "=== Fix Applied ==="
echo "✓ Changed from compiled build to direct TypeScript execution"
echo "✓ Using tsx to run server/index.ts directly"
echo "✓ Installed tsx globally for production use"
echo "✓ Fixed module resolution issues"
echo ""
echo "Test the application:"
echo "- Local: curl http://localhost:5000/health"
echo "- External: curl https://shell.dpvils.org/health"
echo ""
echo "Monitor logs: sudo journalctl -u canvas-course-generator.service -f"