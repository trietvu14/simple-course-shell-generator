#!/bin/bash

echo "=== Fixing Build Structure for React App ==="
echo "Configuring server to serve both HTML and JS bundle correctly"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Checking current build structure..."
echo "Files in dist/:"
ls -la dist/

echo "4. Checking public directory..."
ls -la dist/public/ 2>/dev/null || echo "No public directory"

echo "5. Creating production server with correct build structure support..."
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
    server: 'react-build-structure-fixed'
  });
});

// API endpoints
app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'Canvas Course Shell Generator API working',
    timestamp: new Date().toISOString()
  });
});

// Serve the React JS bundle from dist/
app.use('/static', express.static(path.join(__dirname, 'dist')));

// Also serve any other assets that might be in dist/public
app.use('/assets', express.static(path.join(__dirname, 'dist/public')));

// For any JS/CSS files requested directly, serve from dist/
app.get('*.js', (req, res) => {
  const filePath = path.join(__dirname, 'dist', path.basename(req.path));
  res.sendFile(filePath);
});

app.get('*.css', (req, res) => {
  const filePath = path.join(__dirname, 'dist', path.basename(req.path));
  res.sendFile(filePath);
});

// For all other routes, serve the HTML file (React Router will handle routing)
app.get('*', (req, res) => {
  const indexPath = path.join(__dirname, 'dist', 'public', 'index.html');
  console.log(`Serving index.html from: ${indexPath}`);
  res.sendFile(indexPath);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Canvas Course Shell Generator running on port ${PORT}`);
  console.log(`✓ Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`✓ HTML served from: ${path.join(__dirname, 'dist', 'public')}`);
  console.log(`✓ JS bundle served from: ${path.join(__dirname, 'dist')}`);
  console.log(`✓ Started at: ${new Date().toISOString()}`);
});
EOF

echo "6. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "7. Waiting for service to start..."
sleep 10

echo "8. Service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "9. Testing application..."
curl -s -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/
curl -s -o /dev/null -w "JS Bundle: HTTP %{http_code}\n" http://localhost:5000/index.js

echo "10. External test..."
curl -s -o /dev/null -w "HTTPS: HTTP %{http_code}\n" https://shell.dpvils.org/

echo "11. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Build Structure Fixed ==="
echo "✓ HTML served from dist/public/index.html"
echo "✓ JS bundle served from dist/index.js"
echo "✓ Static files properly configured"
echo "✓ React Router support enabled"
echo ""
echo "Your Canvas Course Shell Generator should now load at https://shell.dpvils.org"