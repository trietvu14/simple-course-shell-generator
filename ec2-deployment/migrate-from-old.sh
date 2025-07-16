#!/bin/bash

echo "🔄 Migrating from old simple-course-shell-generator to new canvas-course-generator..."

# Stop any existing services
echo "Stopping existing services..."
sudo systemctl stop canvas-course-generator 2>/dev/null || true
sudo systemctl stop simple-course-shell-generator 2>/dev/null || true

# Check if old directory exists
if [ -d "/home/ubuntu/simple-course-shell-generator" ]; then
    echo "📁 Found old installation directory..."
    
    # Backup current configurations
    if [ -f "/home/ubuntu/simple-course-shell-generator/.env" ]; then
        echo "💾 Backing up existing .env file..."
        cp /home/ubuntu/simple-course-shell-generator/.env /tmp/old-env-backup
    fi
    
    # Show what's in the old directory
    echo "📋 Contents of old directory:"
    ls -la /home/ubuntu/simple-course-shell-generator/
    
    # Update nginx configuration if it exists
    if [ -f "/etc/nginx/sites-available/canvas-course-generator" ]; then
        echo "🔧 Updating nginx configuration..."
        sudo sed -i 's|/home/ubuntu/simple-course-shell-generator|/home/ubuntu/canvas-course-generator|g' /etc/nginx/sites-available/canvas-course-generator
        sudo nginx -t && sudo systemctl reload nginx
    fi
    
    # Update systemd service path
    if [ -f "/etc/systemd/system/canvas-course-generator.service" ]; then
        echo "🔧 Updating systemd service configuration..."
        sudo sed -i 's|/home/ubuntu/simple-course-shell-generator|/home/ubuntu/canvas-course-generator|g' /etc/systemd/system/canvas-course-generator.service
        sudo systemctl daemon-reload
    fi
    
    # Rename old directory
    echo "📦 Renaming old directory..."
    sudo mv /home/ubuntu/simple-course-shell-generator /home/ubuntu/simple-course-shell-generator.old.$(date +%Y%m%d_%H%M%S)
    
    echo "✅ Migration preparation complete"
else
    echo "ℹ️  No old directory found, proceeding with fresh installation..."
fi

# Create new directory structure
echo "🏗️  Creating new directory structure..."
sudo mkdir -p /home/ubuntu/canvas-course-generator
sudo chown ubuntu:ubuntu /home/ubuntu/canvas-course-generator

# Copy deployment files
echo "📂 Copying React application files..."
cp -r * /home/ubuntu/canvas-course-generator/

# Install dependencies
echo "📦 Installing dependencies..."
cd /home/ubuntu/canvas-course-generator
npm install

# Handle environment file
if [ -f "/tmp/old-env-backup" ]; then
    echo "🔧 Using backed up environment file..."
    cp /tmp/old-env-backup /home/ubuntu/canvas-course-generator/.env
    echo "✅ Environment file restored"
elif [ -f ".env.simple" ]; then
    echo "🔧 Using .env.simple as production environment..."
    cp .env.simple .env
    echo "✅ Environment file configured"
else
    echo "⚠️  No environment file found, will need manual configuration"
fi

# Update database schema
echo "🗄️  Updating database schema..."
if npm run db:push; then
    echo "✅ Database schema updated"
else
    echo "⚠️  Database schema update failed - check DATABASE_URL in .env"
fi

# Start the service
echo "🚀 Starting the new service..."
sudo systemctl start canvas-course-generator

# Check status
sleep 3
echo ""
echo "📊 Service Status:"
sudo systemctl status canvas-course-generator --no-pager

echo ""
echo "🎯 Migration Summary:"
echo "   • Old directory backed up"
echo "   • New React application installed"
echo "   • Environment configuration transferred"
echo "   • Nginx and systemd configurations updated"
echo "   • Service started"
echo ""
echo "🔗 Your application should now be available at: https://shell.dpvils.org"
echo "📋 To check logs: sudo journalctl -u canvas-course-generator -f"