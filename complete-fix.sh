#!/bin/bash

echo "Complete deployment fix for Canvas Course Shell Generator..."

# Stop the service
sudo systemctl stop canvas-course-generator

# Ensure directory exists and has correct permissions
echo "Setting up directory structure..."
sudo mkdir -p /home/ubuntu/simple-course-shell-generator
sudo mkdir -p /home/ubuntu/simple-course-shell-generator/public
sudo chown -R ubuntu:ubuntu /home/ubuntu/simple-course-shell-generator

# Change to the directory
cd /home/ubuntu/simple-course-shell-generator

# Copy the current files to the correct location
echo "Copying application files..."
cp simple-server.js /home/ubuntu/simple-course-shell-generator/ 2>/dev/null || echo "simple-server.js not found in current directory"
cp simple-package.json /home/ubuntu/simple-course-shell-generator/package.json 2>/dev/null || echo "simple-package.json not found"
cp -r public/* /home/ubuntu/simple-course-shell-generator/public/ 2>/dev/null || echo "public directory not found"

# If files don't exist, create them
if [ ! -f "/home/ubuntu/simple-course-shell-generator/simple-server.js" ]; then
    echo "Creating simple-server.js..."
    cat > /home/ubuntu/simple-course-shell-generator/simple-server.js << 'EOF'
const express = require('express');
const { Pool } = require('pg');
const path = require('path');
const session = require('express-session');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false
});

// Session configuration
app.use(session({
  secret: process.env.SESSION_SECRET || 'your-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 }
}));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

// Okta configuration
const OKTA_CLIENT_ID = process.env.OKTA_CLIENT_ID;
const OKTA_CLIENT_SECRET = process.env.OKTA_CLIENT_SECRET;
const OKTA_ISSUER = process.env.OKTA_ISSUER;
const OKTA_REDIRECT_URI = process.env.OKTA_REDIRECT_URI || 'http://localhost:5000/callback';

// Canvas API configuration
const CANVAS_API_URL = process.env.CANVAS_API_URL;
const CANVAS_API_TOKEN = process.env.CANVAS_API_TOKEN;

// Authentication middleware
const requireAuth = (req, res, next) => {
  if (!req.session.user) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  next();
};

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: { status: 'connected' }
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message,
      database: { status: 'disconnected' }
    });
  }
});

// Simple test endpoint
app.get('/test', (req, res) => {
  res.json({ message: 'Server is running!', timestamp: new Date().toISOString() });
});

// Serve frontend
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Canvas Course Shell Generator running on port ${PORT}`);
});
EOF
fi

# Create package.json if it doesn't exist
if [ ! -f "/home/ubuntu/simple-course-shell-generator/package.json" ]; then
    echo "Creating package.json..."
    cat > /home/ubuntu/simple-course-shell-generator/package.json << 'EOF'
{
  "name": "canvas-course-generator",
  "version": "1.0.0",
  "description": "Canvas Course Shell Generator - Simplified",
  "main": "simple-server.js",
  "scripts": {
    "start": "node simple-server.js",
    "dev": "node simple-server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "express-session": "^1.17.3",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
fi

# Create basic HTML file if it doesn't exist
if [ ! -f "/home/ubuntu/simple-course-shell-generator/public/index.html" ]; then
    echo "Creating basic index.html..."
    cat > /home/ubuntu/simple-course-shell-generator/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canvas Course Shell Generator</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #e74c3c;
            text-align: center;
        }
        .status {
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📚 Canvas Course Shell Generator</h1>
        <div class="status">
            <strong>Status:</strong> Server is running successfully!
        </div>
        <p>The simplified Canvas Course Shell Generator is now active.</p>
        <p>This is a basic test page to verify the server is working.</p>
    </div>
</body>
</html>
EOF
fi

# Install dependencies
echo "Installing dependencies..."
npm install

# Create .env file
echo "Creating .env file..."
cat > /home/ubuntu/simple-course-shell-generator/.env << 'EOF'
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://canvas_app:DPVils25!@localhost:5432/canvas_course_generator
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7
OKTA_CLIENT_SECRET=Ez5CUFKEF2-MdAthRXS6EteDzs8sO28iUMDhHyFETDtIaVt1XufExidViy8uGGRz
OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
OKTA_REDIRECT_URI=https://shell.dpvils.org/callback
SESSION_SECRET=03fd8fb82564409ebe0c2678ff5c4fe9
EOF

# Set correct permissions
chown -R ubuntu:ubuntu /home/ubuntu/simple-course-shell-generator

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator
After=network.target
After=postgresql.service

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/simple-course-shell-generator
ExecStart=/usr/bin/node simple-server.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

Environment=NODE_ENV=production
Environment=PORT=5000
Environment=DATABASE_URL=postgresql://canvas_app:DPVils25!@localhost:5432/canvas_course_generator
Environment=CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
Environment=CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
Environment=OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7
Environment=OKTA_CLIENT_SECRET=Ez5CUFKEF2-MdAthRXS6EteDzs8sO28iUMDhHyFETDtIaVt1XufExidViy8uGGRz
Environment=OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
Environment=OKTA_REDIRECT_URI=https://shell.dpvils.org/callback
Environment=SESSION_SECRET=03fd8fb82564409ebe0c2678ff5c4fe9

[Install]
WantedBy=multi-user.target
EOF

# Test the setup
echo "Testing setup..."
echo "Directory structure:"
ls -la /home/ubuntu/simple-course-shell-generator/

echo "Files in public:"
ls -la /home/ubuntu/simple-course-shell-generator/public/

echo "Testing Node.js:"
cd /home/ubuntu/simple-course-shell-generator
node --version
which node

# Start the service
echo "Starting service..."
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator
sudo systemctl start canvas-course-generator

# Check status
echo "Service status:"
sudo systemctl status canvas-course-generator --no-pager

echo ""
echo "Deployment complete!"
echo "Test the server at: https://shell.dpvils.org"
echo "Check logs with: sudo journalctl -u canvas-course-generator -f"