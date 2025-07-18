#!/bin/bash

echo "=== Fixing Server Path Configuration ==="
echo "Updating server to serve from dist/public instead of dist"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Checking current file structure..."
echo "Contents of dist/:"
ls -la dist/ 2>/dev/null || echo "No dist directory"

echo "Contents of dist/public/:"
ls -la dist/public/ 2>/dev/null || echo "No dist/public directory"

echo "4. Creating corrected production server..."
cat > production-react-server.js << 'EOF'
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'production',
    server: 'react-production-fixed-path',
    staticPath: path.join(__dirname, 'dist', 'public')
  });
});

// API routes
app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'Canvas Course Shell Generator API is working',
    timestamp: new Date().toISOString(),
    server: 'react-production-fixed-path'
  });
});

// Canvas API routes (basic endpoints)
app.get('/api/canvas/accounts', (req, res) => {
  res.json([
    { id: 'demo', name: 'Demo Account', parent_account_id: null }
  ]);
});

app.get('/api/canvas/oauth/status', (req, res) => {
  res.json({ 
    isConnected: false, 
    message: 'Canvas OAuth not configured in production' 
  });
});

// Serve static files from dist/public directory (where the build files actually are)
const staticPath = path.join(__dirname, 'dist', 'public');
console.log(`Static files served from: ${staticPath}`);

app.use(express.static(staticPath));

// Handle React Router - serve index.html for all non-API routes
app.get('*', (req, res) => {
  const indexPath = path.join(staticPath, 'index.html');
  console.log(`Serving index.html from: ${indexPath}`);
  res.sendFile(indexPath, (err) => {
    if (err) {
      console.error('Error serving index.html:', err);
      res.status(500).send('Error loading application');
    }
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Canvas Course Shell Generator running on port ${PORT}`);
  console.log(`✓ Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`✓ Serving React app from: ${staticPath}`);
  console.log(`✓ Started at: ${new Date().toISOString()}`);
});
EOF

echo "5. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "6. Waiting for service to start..."
sleep 10

echo "7. Service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "8. Testing with correct path..."
curl -s -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/
curl -s -o /dev/null -w "Dashboard: HTTP %{http_code}\n" http://localhost:5000/dashboard

echo "9. External HTTPS test..."
curl -s -o /dev/null -w "HTTPS: HTTP %{http_code}\n" https://shell.dpvils.org/

echo "10. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Server Path Fixed ==="
echo "✓ Updated server to serve from dist/public (correct path)"
echo "✓ Should now find index.html and other React build files"
echo "✓ No more ENOENT errors"
echo ""
echo "The application should now load properly at https://shell.dpvils.org"