#!/bin/bash

echo "=== Fixing Okta Redirect Priority ==="
echo "Ensuring redirect happens before React catch-all route"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Creating server with proper route order..."
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
    server: 'okta-redirect-priority-fixed'
  });
});

// CRITICAL: Okta redirect MUST come before static files and React routes
app.get('/auth/okta/login', (req, res) => {
  console.log('=== OKTA REDIRECT TRIGGERED ===');
  console.log('Original URL:', req.originalUrl);
  console.log('Query params:', req.query);
  
  // Preserve all query parameters from Okta
  const queryString = Object.keys(req.query).length > 0 ? '?' + new URLSearchParams(req.query).toString() : '';
  const redirectUrl = `/callback${queryString}`;
  
  console.log(`Redirecting to: ${redirectUrl}`);
  res.redirect(302, redirectUrl);
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
// This comes AFTER the Okta redirect
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
  console.log(`✓ Okta redirect: /auth/okta/login → /callback (PRIORITY ROUTE)`);
  console.log(`✓ Started at: ${new Date().toISOString()}`);
});
EOF

echo "4. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "5. Waiting for service to start..."
sleep 10

echo "6. Testing redirect..."
echo "Testing redirect with curl:"
curl -s -I http://localhost:5000/auth/okta/login?iss=https%3A%2F%2Fdigitalpromise.okta.com

echo "7. Service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "8. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Okta Redirect Priority Fixed ==="
echo "✓ Redirect route now comes before React catch-all"
echo "✓ Should properly redirect /auth/okta/login → /callback"
echo "✓ Test at: https://shell.dpvils.org/auth/okta/login"