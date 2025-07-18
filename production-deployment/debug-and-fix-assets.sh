#!/bin/bash

echo "=== Debug and Fix Asset Loading Issues ==="
echo "Checking HTML file and fixing asset serving"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Examining the HTML file to see what assets it's trying to load..."
echo "Contents of dist/public/index.html:"
cat dist/public/index.html

echo ""
echo "4. Checking all files in dist directory..."
find dist -type f -ls

echo ""
echo "5. Creating production server with comprehensive asset serving..."
cat > production-react-server.js << 'EOF'
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Debug middleware to log all requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'production',
    server: 'debug-assets-fixed'
  });
});

// API endpoints
app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'Canvas Course Shell Generator API working',
    timestamp: new Date().toISOString()
  });
});

// Serve all static files from dist directory (for JS bundles)
app.use(express.static(path.join(__dirname, 'dist')));

// Serve static files from dist/public (for HTML and other assets)
app.use(express.static(path.join(__dirname, 'dist/public')));

// Serve assets from any subdirectory in dist
app.use('/assets', express.static(path.join(__dirname, 'dist/assets')));
app.use('/static', express.static(path.join(__dirname, 'dist')));

// Handle specific asset requests with fallback
app.get('*.(css|js|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)', (req, res) => {
  const filename = path.basename(req.path);
  
  // Try different locations for the asset
  const possiblePaths = [
    path.join(__dirname, 'dist', filename),
    path.join(__dirname, 'dist/public', filename),
    path.join(__dirname, 'dist/assets', filename),
    path.join(__dirname, 'dist/public/assets', filename)
  ];
  
  for (const filePath of possiblePaths) {
    if (fs.existsSync(filePath)) {
      console.log(`Found asset: ${filename} at ${filePath}`);
      return res.sendFile(filePath);
    }
  }
  
  console.log(`Asset not found: ${filename}`);
  res.status(404).send('Asset not found');
});

// For all other routes, serve the HTML file
app.get('*', (req, res) => {
  const indexPath = path.join(__dirname, 'dist', 'public', 'index.html');
  
  if (fs.existsSync(indexPath)) {
    console.log(`Serving index.html from: ${indexPath}`);
    res.sendFile(indexPath);
  } else {
    console.log(`index.html not found at: ${indexPath}`);
    res.status(404).send('Application not found');
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Canvas Course Shell Generator running on port ${PORT}`);
  console.log(`✓ Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`✓ Static files served from multiple locations`);
  console.log(`✓ Started at: ${new Date().toISOString()}`);
});
EOF

echo "6. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "7. Waiting for service to start..."
sleep 10

echo "8. Service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "9. Testing various asset paths..."
curl -s -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/
curl -s -o /dev/null -w "Index.js: HTTP %{http_code}\n" http://localhost:5000/index.js
curl -s -o /dev/null -w "Static/index.js: HTTP %{http_code}\n" http://localhost:5000/static/index.js

echo "10. External test..."
curl -s -o /dev/null -w "HTTPS: HTTP %{http_code}\n" https://shell.dpvils.org/

echo "11. Recent logs with asset requests..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 20

echo ""
echo "=== Asset Loading Debug Complete ==="
echo "✓ Added comprehensive asset serving"
echo "✓ Multiple fallback locations for assets"
echo "✓ Debug logging for all requests"
echo "✓ Should resolve stylesheet and JS loading issues"
echo ""
echo "Check the logs above to see what assets are being requested"
echo "The application should now load properly at https://shell.dpvils.org"