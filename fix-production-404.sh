#!/bin/bash

echo "=== Fixing Production 404 Error ==="
echo "Diagnosing and fixing the 404 issue on production server..."

TARGET_DIR="/home/ubuntu/canvas-course-generator"

# Check if we're on the production server
if [ -d "$TARGET_DIR" ]; then
    echo "✓ On production server"
    
    # Stop the service
    echo "1. Stopping service..."
    sudo systemctl stop canvas-course-generator.service
    
    # Check current directory structure
    echo "2. Checking directory structure..."
    ls -la "$TARGET_DIR"
    
    # Check if dist directory exists
    if [ -d "$TARGET_DIR/dist" ]; then
        echo "✓ dist directory exists"
        ls -la "$TARGET_DIR/dist"
    else
        echo "! dist directory missing - building now..."
        cd "$TARGET_DIR"
        npm run build
    fi
    
    # Check if client files exist
    if [ -d "$TARGET_DIR/client" ]; then
        echo "✓ client directory exists"
        if [ -f "$TARGET_DIR/client/index.html" ]; then
            echo "✓ client/index.html exists"
        else
            echo "! client/index.html missing"
        fi
    else
        echo "! client directory missing"
    fi
    
    # Check server files
    if [ -f "$TARGET_DIR/server/index.ts" ]; then
        echo "✓ server/index.ts exists"
    else
        echo "! server/index.ts missing"
    fi
    
    # Check if package.json has correct scripts
    echo "3. Checking package.json scripts..."
    if [ -f "$TARGET_DIR/package.json" ]; then
        echo "Scripts in package.json:"
        grep -A 10 "scripts" "$TARGET_DIR/package.json"
    fi
    
    # Check if environment variables are loaded
    echo "4. Checking environment variables..."
    if [ -f "$TARGET_DIR/.env" ]; then
        echo "✓ .env file exists"
        echo "Environment variables:"
        cat "$TARGET_DIR/.env"
    else
        echo "! .env file missing"
    fi
    
    # Start service
    echo "5. Starting service..."
    sudo systemctl start canvas-course-generator.service
    
    # Check service status
    echo "6. Checking service status..."
    sudo systemctl status canvas-course-generator.service --no-pager
    
    # Test if application responds
    echo "7. Testing application response..."
    sleep 5
    curl -v http://localhost:5000/health 2>&1 | head -20
    
    echo ""
    echo "8. Recent logs..."
    sudo journalctl -u canvas-course-generator.service --no-pager -n 20
    
else
    echo "! Not on production server"
    echo "This script should be run on the production server"
    echo "Creating updated deployment package..."
    
    # Create updated production deployment
    mkdir -p production-deployment-fix
    
    # Copy all files
    cp -r client server shared public *.json *.ts *.js *.md production-deployment-fix/
    cp .env production-deployment-fix/
    
    # Create a fixed systemd service
    cat > production-deployment-fix/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator - React
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
EnvironmentFile=/home/ubuntu/canvas-course-generator/.env
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Create deployment script
    cat > production-deployment-fix/deploy-fix.sh << 'EOF'
#!/bin/bash

echo "=== Deploying Fix to Production ==="

# Stop service
sudo systemctl stop canvas-course-generator.service

# Backup current deployment
sudo cp -r /home/ubuntu/canvas-course-generator /home/ubuntu/backup-$(date +%Y%m%d-%H%M%S)

# Copy new files
sudo cp -r . /home/ubuntu/canvas-course-generator/
sudo chown -R ubuntu:ubuntu /home/ubuntu/canvas-course-generator

# Go to target directory
cd /home/ubuntu/canvas-course-generator

# Install dependencies
npm install

# Build the application
npm run build

# Install systemd service
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service

# Start service
sudo systemctl start canvas-course-generator.service

# Check status
sudo systemctl status canvas-course-generator.service --no-pager

echo "Fix deployment complete!"
echo "Test at: https://shell.dpvils.org"
echo "Check logs: sudo journalctl -u canvas-course-generator.service -f"
EOF

    chmod +x production-deployment-fix/deploy-fix.sh
    
    echo "✓ Updated deployment package created in production-deployment-fix/"
    echo "Upload to server and run: ./deploy-fix.sh"
fi

echo ""
echo "=== Common 404 Fixes ==="
echo "1. Ensure client files are built: npm run build"
echo "2. Check server routing in server/index.ts"
echo "3. Verify environment variables are loaded"
echo "4. Check systemd service configuration"
echo "5. Ensure proper file permissions"