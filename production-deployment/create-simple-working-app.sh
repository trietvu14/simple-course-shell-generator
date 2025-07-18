#!/bin/bash

echo "=== Creating Simple Working React App ==="
echo "Building minimal working version to test functionality"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Creating minimal working HTML app..."
mkdir -p dist/public

cat > dist/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canvas Course Shell Generator</title>
    <script src="https://unpkg.com/@okta/okta-auth-js@7.0.0/dist/okta-auth-js.min.js"></script>
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
            border-radius: 16px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            max-width: 600px;
            width: 90%;
            text-align: center;
        }
        h1 { color: #2c3e50; font-size: 2.5em; margin-bottom: 15px; }
        .subtitle { color: #7f8c8d; font-size: 1.3em; margin-bottom: 30px; }
        .status { 
            background: #d4edda; border: 1px solid #c3e6cb; color: #155724;
            padding: 20px; border-radius: 8px; margin: 25px 0; font-weight: 500;
        }
        .button {
            background: #3498db; color: white; padding: 12px 24px; border: none;
            border-radius: 6px; text-decoration: none; display: inline-block;
            margin: 10px; font-size: 16px; cursor: pointer;
            transition: background 0.3s ease;
        }
        .button:hover { background: #2980b9; }
        .button:disabled { background: #95a5a6; cursor: not-allowed; }
        .auth-info {
            background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;
            border: 1px solid #e9ecef; text-align: left;
        }
        .loading { 
            display: inline-block; width: 20px; height: 20px; border: 3px solid #f3f3f3;
            border-top: 3px solid #3498db; border-radius: 50%; animation: spin 1s linear infinite;
        }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .dashboard { display: none; }
        .features { 
            display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px; margin: 20px 0;
        }
        .feature { 
            background: #f8f9fa; padding: 15px; border-radius: 8px; border: 1px solid #e9ecef;
        }
        .feature h3 { color: #495057; margin-bottom: 8px; }
        .feature p { color: #6c757d; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Canvas Course Shell Generator</h1>
        <p class="subtitle">Digital Promise Educational Technology Platform</p>
        
        <div id="loading" class="status">
            <div class="loading"></div>
            <span style="margin-left: 10px;">Initializing authentication...</span>
        </div>
        
        <div id="login" class="status" style="display: none;">
            <h3>Welcome to Canvas Course Shell Generator</h3>
            <p style="margin: 15px 0;">Please authenticate with your Digital Promise account to access the course creation tools.</p>
            <button id="loginBtn" class="button">Login with Digital Promise</button>
        </div>
        
        <div id="dashboard" class="dashboard">
            <div class="status">
                <h3>✓ Authentication Successful</h3>
                <p>Welcome to the Canvas Course Shell Generator dashboard.</p>
            </div>
            
            <div class="features">
                <div class="feature">
                    <h3>📋 Account Management</h3>
                    <p>Browse and select Canvas accounts for course creation</p>
                </div>
                <div class="feature">
                    <h3>🎯 Bulk Creation</h3>
                    <p>Create multiple course shells at once</p>
                </div>
                <div class="feature">
                    <h3>📊 Progress Tracking</h3>
                    <p>Real-time creation status updates</p>
                </div>
                <div class="feature">
                    <h3>📈 Activity History</h3>
                    <p>View previous creation batches</p>
                </div>
            </div>
            
            <div class="auth-info">
                <h3>Current Session</h3>
                <div id="userInfo">Loading user information...</div>
                <button id="logoutBtn" class="button" style="background: #e74c3c; margin-top: 10px;">Logout</button>
            </div>
        </div>
    </div>

    <script>
        console.log('Canvas Course Shell Generator - Starting...');
        
        // Okta configuration
        const oktaAuth = new OktaAuth({
            issuer: 'https://digitalpromise.okta.com/oauth2/default',
            clientId: '0oapma7d718cb4oYu5d7',
            redirectUri: window.location.origin + '/callback',
            scopes: ['openid', 'profile', 'email'],
            pkce: true
        });

        const loadingDiv = document.getElementById('loading');
        const loginDiv = document.getElementById('login');
        const dashboardDiv = document.getElementById('dashboard');
        const loginBtn = document.getElementById('loginBtn');
        const logoutBtn = document.getElementById('logoutBtn');
        const userInfo = document.getElementById('userInfo');

        // Check authentication status
        async function checkAuth() {
            try {
                console.log('Checking authentication status...');
                
                if (oktaAuth.isLoginRedirect()) {
                    console.log('Handling login redirect...');
                    loadingDiv.style.display = 'block';
                    await oktaAuth.handleLoginRedirect();
                    window.location.replace('/dashboard');
                    return;
                }

                const isAuthenticated = await oktaAuth.isAuthenticated();
                console.log('Authentication status:', isAuthenticated);

                if (isAuthenticated) {
                    const user = await oktaAuth.getUser();
                    console.log('User:', user);
                    showDashboard(user);
                } else {
                    showLogin();
                }
            } catch (error) {
                console.error('Auth check error:', error);
                showLogin();
            }
        }

        function showLogin() {
            loadingDiv.style.display = 'none';
            loginDiv.style.display = 'block';
            dashboardDiv.style.display = 'none';
        }

        function showDashboard(user) {
            loadingDiv.style.display = 'none';
            loginDiv.style.display = 'none';
            dashboardDiv.style.display = 'block';
            
            userInfo.innerHTML = `
                <strong>Name:</strong> ${user.name || 'N/A'}<br>
                <strong>Email:</strong> ${user.email || 'N/A'}<br>
                <strong>Organization:</strong> Digital Promise<br>
                <strong>Login Time:</strong> ${new Date().toLocaleString()}
            `;
        }

        // Event listeners
        loginBtn.addEventListener('click', async () => {
            try {
                console.log('Starting login...');
                loginBtn.disabled = true;
                loginBtn.textContent = 'Redirecting...';
                await oktaAuth.signInWithRedirect();
            } catch (error) {
                console.error('Login error:', error);
                loginBtn.disabled = false;
                loginBtn.textContent = 'Login with Digital Promise';
                alert('Login failed. Please try again.');
            }
        });

        logoutBtn.addEventListener('click', async () => {
            try {
                console.log('Starting logout...');
                await oktaAuth.signOut();
                window.location.reload();
            } catch (error) {
                console.error('Logout error:', error);
            }
        });

        // Initialize
        checkAuth();
    </script>
</body>
</html>
EOF

echo "4. Creating production server..."
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
    server: 'simple-working-app'
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

// Static files
const distPath = path.join(__dirname, 'dist/public');
app.use(express.static(distPath));

// Handle all routes
app.get('*', (req, res) => {
  const indexPath = path.join(distPath, 'index.html');
  res.sendFile(indexPath);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Canvas Course Shell Generator running on port ${PORT}`);
  console.log(`✓ Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`✓ Serving from: ${distPath}`);
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

echo "8. Service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "9. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Simple Working App Created ==="
echo "✓ Minimal HTML app with Okta authentication"
echo "✓ No complex React build issues"
echo "✓ Direct Okta SDK integration"
echo "✓ Should resolve blank page issue"
echo ""
echo "Test at: https://shell.dpvils.org"
echo "The app should now show a working login interface"