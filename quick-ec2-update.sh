#!/bin/bash

# Quick EC2 Update Script
# This script creates a deployment package for the working React application

echo "Creating quick deployment package for EC2..."

# Create deployment structure
mkdir -p ec2-deployment
mkdir -p ec2-deployment/client
mkdir -p ec2-deployment/server
mkdir -p ec2-deployment/shared
mkdir -p ec2-deployment/node_modules

# Copy essential files
cp -r client/ ec2-deployment/
cp -r server/ ec2-deployment/
cp -r shared/ ec2-deployment/
cp package.json ec2-deployment/
cp package-lock.json ec2-deployment/
cp .env ec2-deployment/
cp drizzle.config.ts ec2-deployment/
cp vite.config.ts ec2-deployment/
cp tsconfig.json ec2-deployment/
cp tailwind.config.ts ec2-deployment/
cp postcss.config.js ec2-deployment/
cp components.json ec2-deployment/

# Create updated production server that serves both API and React dev server
cat > ec2-deployment/production-server.js << 'EOF'
const express = require('express');
const path = require('path');
const { spawn } = require('child_process');

// Load environment variables
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start the development server (which includes both API and React)
console.log('Starting development server...');
const devServer = spawn('npm', ['run', 'dev'], {
  stdio: 'inherit',
  env: { ...process.env, NODE_ENV: 'development' }
});

devServer.on('close', (code) => {
  console.log(`Development server exited with code ${code}`);
  process.exit(code);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully...');
  devServer.kill();
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully...');
  devServer.kill();
});

console.log('Production server started, delegating to development server on port', PORT);
EOF

# Create installation script for EC2
cat > ec2-deployment/install-on-ec2.sh << 'EOF'
#!/bin/bash

echo "Installing React Canvas Course Shell Generator on EC2..."

# Stop existing service
sudo systemctl stop canvas-course-generator 2>/dev/null || true

# Backup existing installation
if [ -d "/home/ubuntu/canvas-course-generator" ]; then
    sudo mv /home/ubuntu/canvas-course-generator /home/ubuntu/canvas-course-generator.backup.$(date +%Y%m%d_%H%M%S)
fi

# Create installation directory
sudo mkdir -p /home/ubuntu/canvas-course-generator
sudo chown ubuntu:ubuntu /home/ubuntu/canvas-course-generator

# Copy all files
cp -r * /home/ubuntu/canvas-course-generator/

# Install dependencies
cd /home/ubuntu/canvas-course-generator
npm install

# Update database schema
npm run db:push

# Create systemd service file
cat > canvas-course-generator.service << 'SYSTEMD_EOF'
[Unit]
Description=Canvas Course Shell Generator (React)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
ExecStart=/usr/bin/node production-server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

# Install and start service
sudo mv canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator
sudo systemctl start canvas-course-generator

# Check service status
sleep 5
sudo systemctl status canvas-course-generator

echo "Installation complete!"
echo "Service status:"
sudo systemctl is-active canvas-course-generator
echo "To view logs: sudo journalctl -u canvas-course-generator -f"
EOF

chmod +x ec2-deployment/install-on-ec2.sh

# Create README for deployment
cat > ec2-deployment/README.md << 'EOF'
# EC2 Deployment Instructions

## Files included:
- Complete React application with working authentication
- Production server configuration
- Automatic installation script

## To deploy:

1. Upload this entire directory to your EC2 instance:
   ```bash
   scp -r ec2-deployment/ ubuntu@your-ec2-ip:/home/ubuntu/
   ```

2. SSH into your EC2 instance:
   ```bash
   ssh ubuntu@your-ec2-ip
   ```

3. Run the installation script:
   ```bash
   cd /home/ubuntu/ec2-deployment
   chmod +x install-on-ec2.sh
   ./install-on-ec2.sh
   ```

4. The application will be available at https://shell.dpvils.org

## What this deployment does:
- Stops the current simple-server.js version
- Installs the full React application
- Starts a production server that runs the development server (includes both API and React)
- Creates a systemd service for automatic startup
- Updates the database schema

## To check status:
```bash
sudo systemctl status canvas-course-generator
sudo journalctl -u canvas-course-generator -f
```
EOF

echo "✅ Deployment package created in ec2-deployment/"
echo ""
echo "📋 To deploy to your EC2 instance:"
echo "1. Upload the ec2-deployment/ directory to your server"
echo "2. SSH into your EC2 instance"
echo "3. Run: cd ec2-deployment && chmod +x install-on-ec2.sh && ./install-on-ec2.sh"
echo ""
echo "🌐 This will replace the simple-server.js with the working React application"