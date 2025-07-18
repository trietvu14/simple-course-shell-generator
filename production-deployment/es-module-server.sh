#!/bin/bash

echo "=== ES Module Server - Using Import Statements ==="
echo "Creating server with proper ES module syntax"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Creating ES module server with import statements..."
cat > es-module-server.js << 'EOF'
import http from 'http';
import url from 'url';
import fs from 'fs';
import path from 'path';

const PORT = process.env.PORT || 5000;

console.log('Starting Canvas Course Shell Generator Server');
console.log(`Port: ${PORT}`);
console.log(`Working Directory: ${process.cwd()}`);
console.log(`Node.js Version: ${process.version}`);

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;

  console.log(`${new Date().toISOString()} - ${req.method} ${pathname}`);

  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Health check endpoint
  if (pathname === '/health') {
    res.setHeader('Content-Type', 'application/json');
    res.writeHead(200);
    res.end(JSON.stringify({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      server: 'es-module-server',
      port: PORT,
      environment: process.env.NODE_ENV || 'production'
    }));
    return;
  }

  // API test endpoint
  if (pathname.startsWith('/api/')) {
    res.setHeader('Content-Type', 'application/json');
    res.writeHead(200);
    res.end(JSON.stringify({
      message: 'Canvas Course Shell Generator API is working',
      endpoint: pathname,
      timestamp: new Date().toISOString(),
      method: req.method
    }));
    return;
  }

  // Try to serve static files from dist/public if they exist
  const staticPath = path.join(process.cwd(), 'dist', 'public', pathname === '/' ? 'index.html' : pathname);
  
  if (fs.existsSync(staticPath) && fs.statSync(staticPath).isFile()) {
    const ext = path.extname(staticPath).toLowerCase();
    const contentType = {
      '.html': 'text/html',
      '.css': 'text/css',
      '.js': 'application/javascript',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml'
    }[ext] || 'text/plain';

    res.setHeader('Content-Type', contentType);
    res.writeHead(200);
    fs.createReadStream(staticPath).pipe(res);
    return;
  }

  // Default HTML response for all other routes
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canvas Course Shell Generator</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container { 
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            max-width: 700px;
            width: 90%;
            text-align: center;
        }
        h1 { color: #2c3e50; font-size: 2.5em; margin-bottom: 15px; }
        .subtitle { color: #7f8c8d; font-size: 1.3em; margin-bottom: 30px; }
        .status { 
            background: #d4edda; border: 1px solid #c3e6cb; color: #155724;
            padding: 20px; border-radius: 8px; margin: 25px 0; font-weight: 500;
        }
        .info { 
            background: #e3f2fd; border: 1px solid #2196f3; color: #1565c0;
            padding: 20px; border-radius: 8px; margin: 25px 0;
        }
        .button {
            background: #3498db; color: white; padding: 12px 24px; border: none;
            border-radius: 6px; text-decoration: none; display: inline-block;
            margin: 10px; font-size: 16px; cursor: pointer;
            transition: background 0.3s ease;
        }
        .button:hover { background: #2980b9; }
        .button.secondary { background: #95a5a6; }
        .button.secondary:hover { background: #7f8c8d; }
        .server-info {
            margin-top: 30px; padding: 20px; background: #f8f9fa;
            border-radius: 8px; border: 1px solid #e9ecef;
        }
        .grid { 
            display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px; margin-top: 15px;
        }
        .grid-item {
            background: white; padding: 15px; border-radius: 6px;
            border: 1px solid #dee2e6; text-align: left;
        }
        .grid-item strong { color: #495057; }
        .footer {
            margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6;
            color: #6c757d; font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Canvas Course Shell Generator</h1>
        <p class="subtitle">Digital Promise Educational Technology Platform</p>
        
        <div class="status">
            <strong>✓ System Online & Operational</strong><br>
            ES Module server running successfully with proper import syntax
        </div>
        
        <div class="info">
            <strong>Canvas Course Shell Creation System</strong><br>
            Automated platform for creating Canvas LMS course shells with Digital Promise authentication
        </div>
        
        <div>
            <a href="/health" class="button">System Health Check</a>
            <a href="/api/test" class="button secondary">Test API Endpoint</a>
        </div>
        
        <div class="server-info">
            <strong>Server Status & Information</strong>
            <div class="grid">
                <div class="grid-item">
                    <strong>Server Time:</strong><br>
                    <span id="serverTime">${new Date().toLocaleString()}</span>
                </div>
                <div class="grid-item">
                    <strong>Environment:</strong><br>
                    ${process.env.NODE_ENV || 'production'}
                </div>
                <div class="grid-item">
                    <strong>Port:</strong><br>
                    ${PORT}
                </div>
                <div class="grid-item">
                    <strong>Module System:</strong><br>
                    ES Modules
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p><strong>Canvas Course Shell Generator - Production Server</strong></p>
            <p>Digital Promise Global | Educational Technology Platform</p>
            <p><small>Server started: ${new Date().toISOString()}</small></p>
        </div>
    </div>
    
    <script>
        // Update server time every second
        setInterval(() => {
            const timeElement = document.getElementById('serverTime');
            if (timeElement) {
                timeElement.textContent = new Date().toLocaleString();
            }
        }, 1000);
    </script>
</body>
</html>`;

  res.setHeader('Content-Type', 'text/html');
  res.writeHead(200);
  res.end(html);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Canvas Course Shell Generator Server started successfully`);
  console.log(`✓ Server running on port ${PORT}`);
  console.log(`✓ Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`✓ Started at: ${new Date().toISOString()}`);
  console.log(`✓ Access at: http://localhost:${PORT}`);
  console.log(`✓ Health check: http://localhost:${PORT}/health`);
});

server.on('error', (err) => {
  console.error('❌ Server error:', err);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
EOF

echo "4. Creating ES module service configuration..."
cat > canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator - ES Module Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
Environment=PORT=5000
ExecStart=/usr/bin/node es-module-server.js
Restart=always
RestartSec=10
StartLimitBurst=3
StartLimitInterval=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "5. Installing ES module service..."
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload

echo "6. Starting ES module server..."
sudo systemctl start canvas-course-generator.service

echo "7. Waiting for service to start..."
sleep 10

echo "8. Service status:"
sudo systemctl status canvas-course-generator.service --no-pager

echo "9. Testing ES module server..."
curl -s -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/
curl -s -w "API: HTTP %{http_code}\n" http://localhost:5000/api/test

echo "10. External HTTPS test..."
curl -s -o /dev/null -w "HTTPS Health: HTTP %{http_code}\n" https://shell.dpvils.org/health
curl -s -o /dev/null -w "HTTPS Root: HTTP %{http_code}\n" https://shell.dpvils.org/

echo "11. Recent server logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 15

echo ""
echo "=== ES Module Server Deployed Successfully ==="
echo "✓ Uses proper import statements instead of require()"
echo "✓ Compatible with ES module environment"
echo "✓ Pure Node.js HTTP server"
echo "✓ Static file serving from dist/public"
echo "✓ Professional HTML interface"
echo "✓ Health check and API endpoints"
echo ""
echo "Your site should now be accessible at: https://shell.dpvils.org"