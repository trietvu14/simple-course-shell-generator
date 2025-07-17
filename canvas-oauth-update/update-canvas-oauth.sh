#!/bin/bash

echo "=== Updating Canvas OAuth Implementation ==="

APP_DIR="/home/ubuntu/canvas-course-generator"
BACKUP_DIR="/home/ubuntu/canvas-course-generator-backup-$(date +%Y%m%d_%H%M%S)"

# Create backup
echo "1. Creating backup..."
sudo cp -r "$APP_DIR" "$BACKUP_DIR"
echo "Backup created at: $BACKUP_DIR"

# Stop the service
echo "2. Stopping service..."
sudo systemctl stop canvas-course-generator.service

# Copy new files
echo "3. Copying updated files..."
sudo cp -r ec2-production/* "$APP_DIR/"

# Update database schema
echo "4. Updating database schema..."
cd "$APP_DIR"
sudo -u ubuntu npm run db:push

# Update environment variables
echo "5. Environment variables needed:"
echo "Please add these to your .env file:"
echo "CANVAS_CLIENT_ID=your_canvas_client_id"
echo "CANVAS_CLIENT_SECRET=your_canvas_client_secret"
echo "CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback"
echo "SESSION_SECRET=your_secure_session_secret"

echo "6. Restarting service..."
sudo systemctl start canvas-course-generator.service

echo "7. Checking service status..."
sleep 5
if sudo systemctl is-active --quiet canvas-course-generator.service; then
    echo "✅ Service is running!"
    echo "✅ Canvas OAuth refresh token system is now active"
    echo ""
    echo "Next steps:"
    echo "1. Set up Canvas developer key (see setup-canvas-oauth.md)"
    echo "2. Add environment variables to .env file"
    echo "3. Test OAuth flow at https://shell.dpvils.org"
else
    echo "❌ Service failed to start. Checking logs..."
    sudo journalctl -u canvas-course-generator.service -n 20 --no-pager
    echo ""
    echo "To restore backup:"
    echo "sudo systemctl stop canvas-course-generator.service"
    echo "sudo rm -rf $APP_DIR"
    echo "sudo mv $BACKUP_DIR $APP_DIR"
    echo "sudo systemctl start canvas-course-generator.service"
fi

echo "=== Update Complete ==="