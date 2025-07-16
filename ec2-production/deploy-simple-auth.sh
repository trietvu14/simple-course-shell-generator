#!/bin/bash

echo "=== Deploying Simple Authentication to EC2 ==="

# Set variables
APP_DIR="/home/ubuntu/canvas-course-generator"
BACKUP_DIR="/home/ubuntu/canvas-course-generator-backup-$(date +%Y%m%d-%H%M%S)"

# Create backup
echo "1. Creating backup of current application..."
sudo cp -r "$APP_DIR" "$BACKUP_DIR"
echo "✓ Backup created at: $BACKUP_DIR"

# Stop the service
echo "2. Stopping canvas-course-generator service..."
sudo systemctl stop canvas-course-generator.service

# Copy updated files
echo "3. Copying updated files..."
cd "$(dirname "$0")" # Go to ec2-production directory

# Update server files
sudo cp -r ../server/* "$APP_DIR/server/"
sudo cp -r ../client/* "$APP_DIR/client/"
sudo cp -r ../shared/* "$APP_DIR/shared/"

# Update configuration files
sudo cp .env "$APP_DIR/.env"
sudo cp nginx-site.conf /etc/nginx/sites-available/canvas-course-generator
sudo cp start-production.cjs "$APP_DIR/start-production.cjs"

# Set proper permissions
echo "4. Setting proper permissions..."
sudo chown -R ubuntu:ubuntu "$APP_DIR"
sudo chmod +x "$APP_DIR/start-production.cjs"

# Test nginx configuration
echo "5. Testing nginx configuration..."
sudo nginx -t
if [ $? -ne 0 ]; then
    echo "❌ Nginx configuration test failed. Check the configuration."
    exit 1
fi

# Reload nginx
echo "6. Reloading nginx..."
sudo systemctl reload nginx

# Start the service
echo "7. Starting canvas-course-generator service..."
sudo systemctl start canvas-course-generator.service

# Wait for service to start
echo "8. Waiting for service to start..."
sleep 5

# Check service status
echo "9. Checking service status..."
if sudo systemctl is-active --quiet canvas-course-generator.service; then
    echo "✅ Service is running successfully!"
else
    echo "❌ Service failed to start. Checking logs..."
    sudo journalctl -u canvas-course-generator.service -n 20 --no-pager
    exit 1
fi

# Test the application
echo "10. Testing application..."
if curl -s -f http://localhost:5000/health > /dev/null; then
    echo "✅ Application is responding to health checks!"
else
    echo "❌ Application is not responding. Check logs."
    sudo journalctl -u canvas-course-generator.service -n 10 --no-pager
    exit 1
fi

echo ""
echo "=== Deployment Complete! ==="
echo "✅ Simple authentication has been deployed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Visit https://shell.dpvils.org"
echo "2. You should see a simple login screen (not Okta)"
echo "3. Login with: admin / P@ssword01"
echo "4. Test the Canvas course shell generation features"
echo ""
echo "🔧 If you encounter issues:"
echo "- Check logs: sudo journalctl -u canvas-course-generator.service -f"
echo "- Check nginx: sudo tail -f /var/log/nginx/error.log"
echo "- Restart service: sudo systemctl restart canvas-course-generator.service"
echo "- Restore backup: sudo rm -rf $APP_DIR && sudo mv $BACKUP_DIR $APP_DIR"
echo ""
echo "🎯 Login credentials:"
echo "Username: admin"
echo "Password: P@ssword01"