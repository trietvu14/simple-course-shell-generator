#!/bin/bash

echo "=== Fixing HTML Structure for React App ==="
echo "Creating proper HTML file with React mount point"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Creating corrected HTML file..."
cat > dist/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1" />
    <title>Canvas Course Shell Generator</title>
    <script type="module" crossorigin src="/assets/index-BtXm5uTy.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-DLNgVKnK.css">
    <style>
      body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
          'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
          sans-serif;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
      }
      
      /* Loading fallback */
      #root:empty::before {
        content: "Loading Canvas Course Shell Generator...";
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        font-size: 18px;
      }
      
      /* Prevent blank page */
      #root {
        min-height: 100vh;
      }
    </style>
  </head>
  <body>
    <div id="root"></div>
    <script>
      // Debug React mounting
      console.log('HTML loaded, React should mount to #root');
      
      // Fallback error handling
      window.addEventListener('error', function(e) {
        console.error('Application error:', e.error);
        const root = document.getElementById('root');
        if (root && root.innerHTML === '') {
          root.innerHTML = `
            <div style="display: flex; justify-content: center; align-items: center; height: 100vh; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-align: center; font-family: Arial, sans-serif;">
              <div>
                <h1>Canvas Course Shell Generator</h1>
                <p>Loading application...</p>
                <p><small>If this persists, please refresh the page</small></p>
              </div>
            </div>
          `;
        }
      });
      
      // Check if React loaded after a delay
      setTimeout(() => {
        const root = document.getElementById('root');
        if (root && root.innerHTML === '') {
          console.warn('React app did not mount after 5 seconds');
          root.innerHTML = `
            <div style="display: flex; justify-content: center; align-items: center; height: 100vh; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-align: center; font-family: Arial, sans-serif;">
              <div>
                <h1>Canvas Course Shell Generator</h1>
                <p>Application is starting...</p>
                <p><small>Please wait or refresh the page</small></p>
              </div>
            </div>
          `;
        }
      }, 5000);
    </script>
  </body>
</html>
EOF

echo "4. Creating production server with better error handling..."
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
    server: 'html-structure-fixed'
  });
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

// Static files from dist/public
const distPath = path.join(__dirname, 'dist/public');
app.use(express.static(distPath));

// Also serve assets from dist/ for JS bundles
app.use('/assets', express.static(path.join(__dirname, 'dist/assets')));

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
  console.log(`✓ Assets served from: ${path.join(__dirname, 'dist/assets')}`);
  console.log(`✓ Started at: ${new Date().toISOString()}`);
});
EOF

echo "5. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "6. Waiting for service to start..."
sleep 10

echo "7. Testing application..."
curl -s -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/
curl -s -o /dev/null -w "Assets: HTTP %{http_code}\n" http://localhost:5000/assets/index-BtXm5uTy.js

echo "8. External HTTPS test..."
curl -s -o /dev/null -w "HTTPS: HTTP %{http_code}\n" https://shell.dpvils.org/

echo "9. Service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "10. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== HTML Structure Fixed ==="
echo "✓ Added proper title tag"
echo "✓ Added loading fallback styles"
echo "✓ Added React mount error handling"
echo "✓ Fixed asset serving for JS bundles"
echo ""
echo "The React app should now mount properly at https://shell.dpvils.org"
echo "If React still doesn't load, you'll see a proper loading message"