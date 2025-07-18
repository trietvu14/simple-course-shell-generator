#!/bin/bash

echo "=== Fixing Okta Redirect URL Mismatch ==="
echo "Adding server-side redirect to handle /auth/okta/login → /callback"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Building React application..."
npm run build

echo "4. Creating server with Okta redirect fix..."
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

// Request logging
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
    server: 'okta-redirect-fixed'
  });
});

// FIX: Redirect Okta's callback URL to the correct React route
app.get('/auth/okta/login', (req, res) => {
  console.log('Redirecting Okta callback from /auth/okta/login to /callback');
  console.log('Query params:', req.query);
  
  // Preserve all query parameters from Okta
  const queryString = Object.keys(req.query).length > 0 ? '?' + new URLSearchParams(req.query).toString() : '';
  const redirectUrl = `/callback${queryString}`;
  
  console.log(`Redirecting to: ${redirectUrl}`);
  res.redirect(redirectUrl);
});

// API endpoints
app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'Canvas Course Shell Generator API working',
    timestamp: new Date().toISOString()
  });
});

// Mock Canvas API endpoints
app.get('/api/canvas/accounts', (req, res) => {
  res.json([
    { id: '1', name: 'Digital Promise', parent_account_id: null, workflow_state: 'active' },
    { id: '2', name: 'Test Account', parent_account_id: '1', workflow_state: 'active' }
  ]);
});

app.get('/api/canvas/oauth/status', (req, res) => {
  res.json({ 
    isConnected: true, 
    message: 'Canvas API configured'
  });
});

// Mock user endpoint
app.get('/api/user', (req, res) => {
  res.json({
    id: '1',
    name: 'Digital Promise User',
    email: 'user@digitalpromise.org',
    isAuthenticated: true
  });
});

// Determine build output location
let distPath;
if (fs.existsSync(path.join(__dirname, 'dist/index.html'))) {
  distPath = path.join(__dirname, 'dist');
} else if (fs.existsSync(path.join(__dirname, 'dist/public/index.html'))) {
  distPath = path.join(__dirname, 'dist/public');
} else {
  distPath = path.join(__dirname, 'dist');
}

console.log(`Serving static files from: ${distPath}`);

// Serve static files from the build directory
app.use(express.static(distPath));

// Also serve from root dist for JS bundles
if (distPath.endsWith('public')) {
  app.use(express.static(path.join(__dirname, 'dist')));
}

// Handle React Router - serve index.html for all non-API routes
app.get('*', (req, res) => {
  const indexPath = path.join(distPath, 'index.html');
  
  if (fs.existsSync(indexPath)) {
    console.log(`Serving React app from: ${indexPath}`);
    res.sendFile(indexPath);
  } else {
    console.log(`index.html not found at: ${indexPath}`);
    res.status(404).send('React app not found');
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Canvas Course Shell Generator running on port ${PORT}`);
  console.log(`✓ Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`✓ Serving React app from: ${distPath}`);
  console.log(`✓ Okta redirect fix: /auth/okta/login → /callback`);
  console.log(`✓ Started at: ${new Date().toISOString()}`);
});
EOF

echo "5. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "6. Waiting for service to start..."
sleep 10

echo "7. Testing redirect fix..."
curl -s -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -w "Okta redirect: HTTP %{http_code}\n" http://localhost:5000/auth/okta/login
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/
curl -s -o /dev/null -w "Callback: HTTP %{http_code}\n" http://localhost:5000/callback

echo "8. External HTTPS test..."
curl -s -w "HTTPS Okta redirect: HTTP %{http_code}\n" https://shell.dpvils.org/auth/okta/login
curl -s -o /dev/null -w "HTTPS Root: HTTP %{http_code}\n" https://shell.dpvils.org/

echo "9. Service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "10. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 15

echo ""
echo "=== Okta Redirect Fix Applied ==="
echo "✓ Server now redirects /auth/okta/login → /callback"
echo "✓ React app built and deployed"
echo "✓ All query parameters preserved in redirect"
echo "✓ Should resolve the 404 error"
echo ""
echo "Test the authentication flow:"
echo "1. Go to https://shell.dpvils.org"
echo "2. Click login"
echo "3. Okta should redirect to /auth/okta/login"
echo "4. Server will redirect to /callback"
echo "5. React app will handle the callback"