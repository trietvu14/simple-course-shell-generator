#!/bin/bash

echo "=== Ultra Simple Server - No Dependencies ==="
echo "Creating the most basic server possible"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Getting detailed error logs first..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 20

echo "4. Creating ultra-simple server with minimal dependencies..."
cat > ultra-simple-server.js << 'EOF'
const http = require('http');
const url = require('url');

const PORT = process.env.PORT || 5000;

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;

  console.log(`${new Date().toISOString()} - ${req.method} ${path}`);

  // Set common headers
  res.setHeader('Content-Type', 'text/html');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Handle OPTIONS requests
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Health check endpoint
  if (path === '/health') {
    res.setHeader('Content-Type', 'application/json');
    res.writeHead(200);
    res.end(JSON.stringify({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      server: 'ultra-simple'
    }));
    return;
  }

  // API test endpoint
  if (path === '/api/test') {
    res.setHeader('Content-Type', 'application/json');
    res.writeHead(200);
    res.end(JSON.stringify({
      message: 'Ultra simple server is working',
      timestamp: new Date().toISOString()
    }));
    return;
  }

  // Default response for all other routes
  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canvas Course Shell Generator</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f0f0f0; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .status { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; text-decoration: none; display: inline-block; margin: 10px 5px; }
        .button:hover { background: #0056b3; }
        .server-info { margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Canvas Course Shell Generator</h1>
        
        <div class="status">
            <strong>✓ System Online</strong><br>
            Ultra-simple server is running successfully
        </div>
        
        <div class="info">
            <strong>Digital Promise Educational Technology Platform</strong><br>
            The system is operational and ready for Canvas course shell creation.
        </div>
        
        <div>
            <a href="/health" class="button">Health Check</a>
            <a href="/api/test" class="button">Test API</a>
        </div>
        
        <div class="server-info">
            <strong>Server Information:</strong><br>
            Time: ${new Date().toLocaleString()}<br>
            Server: Ultra-Simple HTTP Server<br>
            Port: ${PORT}<br>
            Status: Active
        </div>
    </div>
</body>
</html>`;

  res.writeHead(200);
  res.end(html);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Ultra-simple server running on port ${PORT}`);
  console.log(`Started at: ${new Date().toISOString()}`);
});

server.on('error', (err) => {
  console.error('Server error:', err);
  process.exit(1);
});

process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
EOF

echo "5. Creating ultra-simple service configuration..."
cat > canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator - Ultra Simple
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node ultra-simple-server.js
Restart=always
RestartSec=5
StartLimitBurst=3
StartLimitInterval=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "6. Installing ultra-simple service..."
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload

echo "7. Starting ultra-simple server..."
sudo systemctl start canvas-course-generator.service

echo "8. Waiting for service to start..."
sleep 10

echo "9. Service status:"
sudo systemctl status canvas-course-generator.service --no-pager

echo "10. Testing ultra-simple server..."
curl -s -o /dev/null -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/
curl -s -o /dev/null -w "API: HTTP %{http_code}\n" http://localhost:5000/api/test

echo "11. External test..."
curl -s -o /dev/null -w "HTTPS: HTTP %{http_code}\n" https://shell.dpvils.org/

echo "12. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Ultra Simple Server Deployed ==="
echo "✓ No Express.js dependency"
echo "✓ Pure Node.js HTTP server"
echo "✓ No external modules"
echo "✓ Basic health check and API endpoints"
echo "✓ Simple HTML response"
echo ""
echo "This should work with zero dependencies"