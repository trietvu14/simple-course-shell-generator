#!/bin/bash

# Deploy React Application to EC2
# This script updates the EC2 instance with the working React application

echo "🚀 Starting deployment of React application to EC2..."

# Build the React application for production
echo "📦 Building React application..."
npm run build

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Build failed! Please fix build errors first."
    exit 1
fi

# Create deployment directory structure
echo "📁 Creating deployment structure..."
mkdir -p deployment/react-app
mkdir -p deployment/react-app/dist
mkdir -p deployment/react-app/server

# Copy built files
echo "📋 Copying built files..."
cp -r dist/* deployment/react-app/dist/
cp -r server/* deployment/react-app/server/
cp -r shared deployment/react-app/
cp package.json deployment/react-app/
cp package-lock.json deployment/react-app/
cp .env deployment/react-app/.env
cp drizzle.config.ts deployment/react-app/

# Create production server file
echo "🖥️ Creating production server..."
cat > deployment/react-app/server/prod-server.js << 'EOF'
const express = require('express');
const path = require('path');
const { createServer } = require('http');

// Load environment variables
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Import and register API routes
const { registerRoutes } = require('./routes');

async function startServer() {
  // Register API routes
  const server = await registerRoutes(app);
  
  // Serve static files from dist directory
  app.use(express.static(path.join(__dirname, '../dist')));
  
  // Handle client-side routing - serve index.html for all non-API routes
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../dist/index.html'));
  });
  
  // Start server
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
  });
}

startServer().catch(console.error);
EOF

# Create systemd service file
echo "⚙️ Creating systemd service file..."
cat > deployment/react-app/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator (React)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
ExecStart=/usr/bin/node server/prod-server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Create installation script
echo "📝 Creating installation script..."
cat > deployment/react-app/install.sh << 'EOF'
#!/bin/bash

echo "🔧 Installing React application on EC2..."

# Stop existing service
sudo systemctl stop canvas-course-generator || true

# Remove old installation
sudo rm -rf /home/ubuntu/canvas-course-generator

# Create new directory
sudo mkdir -p /home/ubuntu/canvas-course-generator
sudo chown ubuntu:ubuntu /home/ubuntu/canvas-course-generator

# Copy files
cp -r * /home/ubuntu/canvas-course-generator/

# Install dependencies
cd /home/ubuntu/canvas-course-generator
npm install --production

# Update database schema
npm run db:push

# Install systemd service
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator
sudo systemctl start canvas-course-generator

# Check service status
sudo systemctl status canvas-course-generator

echo "✅ React application installed successfully!"
echo "🌐 Application should be available at https://shell.dpvils.org"
EOF

chmod +x deployment/react-app/install.sh

echo "✅ Deployment package created in deployment/react-app/"
echo ""
echo "📋 To deploy to EC2, run these commands on your server:"
echo "1. Upload the deployment/react-app/ directory to your EC2 instance"
echo "2. ssh into your EC2 instance"
echo "3. cd to the uploaded directory"
echo "4. run: chmod +x install.sh && ./install.sh"
echo ""
echo "🔄 The React application will replace the simple-server.js version"