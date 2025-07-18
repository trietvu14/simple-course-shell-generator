#!/bin/bash

echo "=== Alternative Build Fix for 502 Error ==="
echo "Creating proper production build with static file serving"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

# Stop service
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

cd "$TARGET_DIR"

# Clean previous build
echo "2. Cleaning previous build..."
rm -rf dist/ build/

# Build frontend only (static files)
echo "3. Building frontend for production..."
npm run build

# Check if build was successful
if [ -d "dist" ]; then
    echo "✓ Frontend build successful"
    ls -la dist/
else
    echo "✗ Frontend build failed"
    exit 1
fi

# Create a simple production server that serves static files and API
echo "4. Creating production server..."
cat > production-server.js << 'EOF'
const express = require('express');
const path = require('path');
const { createServer } = require('http');

const app = express();
const PORT = process.env.PORT || 5000;

// Serve static files from dist directory
app.use(express.static(path.join(__dirname, 'dist')));

// API routes would go here
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/test', (req, res) => {
  res.json({ message: 'API is working' });
});

// Serve React app for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'));
});

const server = createServer(app);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
EOF

# Create systemd service for simple server
echo "5. Creating systemd service for simple server..."
cat > canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator - Simple Production
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
EnvironmentFile=/home/ubuntu/canvas-course-generator/.env
ExecStart=/usr/bin/node production-server.js
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

# Install service
echo "6. Installing service..."
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload

# Start service
echo "7. Starting service..."
sudo systemctl start canvas-course-generator.service

# Wait and check
echo "8. Waiting for service..."
sleep 10

echo "9. Service status..."
sudo systemctl status canvas-course-generator.service --no-pager

# Test
echo "10. Testing..."
curl -s -o /dev/null -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/

echo ""
echo "=== Simple Production Server Started ==="
echo "This serves static files and basic API endpoints"
echo "Once working, we can integrate the full Canvas API"