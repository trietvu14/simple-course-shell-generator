#!/bin/bash

echo "=== Deploying Canvas Connection Button ==="

APP_DIR="/home/ubuntu/canvas-course-generator"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo"
   exit 1
fi

# Create backup
BACKUP_DIR="/home/ubuntu/canvas-course-generator-backup-$(date +%Y%m%d_%H%M%S)"
echo "1. Creating backup..."
cp -r "$APP_DIR" "$BACKUP_DIR"
echo "Backup created at: $BACKUP_DIR"

# Stop the service
echo "2. Stopping service..."
systemctl stop canvas-course-generator.service

# Copy Canvas connection files
echo "3. Copying Canvas connection files..."

# Frontend files
echo "  - Copying canvas-connection.tsx..."
cp "$SCRIPT_DIR/client/src/components/canvas-connection.tsx" "$APP_DIR/client/src/components/"

echo "  - Copying UI components (badge, card)..."
cp "$SCRIPT_DIR/client/src/components/ui/badge.tsx" "$APP_DIR/client/src/components/ui/"
cp "$SCRIPT_DIR/client/src/components/ui/card.tsx" "$APP_DIR/client/src/components/ui/"

echo "  - Copying updated dashboard.tsx..."
cp "$SCRIPT_DIR/client/src/pages/dashboard.tsx" "$APP_DIR/client/src/pages/"

# Backend files
echo "  - Copying canvas-oauth.ts..."
cp "$SCRIPT_DIR/server/canvas-oauth.ts" "$APP_DIR/server/"

echo "  - Copying updated routes.ts..."
cp "$SCRIPT_DIR/server/routes.ts" "$APP_DIR/server/"

echo "  - Copying updated storage.ts..."
cp "$SCRIPT_DIR/server/storage.ts" "$APP_DIR/server/"

# Schema
echo "  - Copying updated schema.ts..."
cp "$SCRIPT_DIR/shared/schema.ts" "$APP_DIR/shared/"

# Set proper permissions
echo "4. Setting file permissions..."
chown -R ubuntu:ubuntu "$APP_DIR"
chmod -R 755 "$APP_DIR"

# Update database schema
echo "5. Updating database schema..."
cd "$APP_DIR"
sudo -u ubuntu npm run db:push

# Restart service
echo "6. Restarting service..."
systemctl start canvas-course-generator.service

# Check service status
echo "7. Checking service status..."
sleep 5
if systemctl is-active --quiet canvas-course-generator.service; then
    echo "✅ Service is running!"
    echo "✅ Canvas connection button deployed successfully!"
    echo ""
    echo "What you'll see:"
    echo "- Canvas Connection card at top of dashboard"
    echo "- 'Connect Canvas' button (shows 'Setup Required' until OAuth configured)"
    echo "- Course shells continue working with static API token"
    echo ""
    echo "Optional next steps:"
    echo "1. Set up Canvas developer key (see setup-canvas-oauth.md)"
    echo "2. Add Canvas OAuth environment variables"
    echo "3. Test at https://shell.dpvils.org"
else
    echo "❌ Service failed to start. Checking logs..."
    journalctl -u canvas-course-generator.service -n 20 --no-pager
    echo ""
    echo "To restore backup:"
    echo "systemctl stop canvas-course-generator.service"
    echo "rm -rf $APP_DIR"
    echo "mv $BACKUP_DIR $APP_DIR"
    echo "systemctl start canvas-course-generator.service"
fi

echo "=== Canvas Connection Deployment Complete ==="
echo ""
echo "🔧 To test Canvas OAuth on production:"
echo "1. Make sure your production .env has:"
echo "   CANVAS_CLIENT_ID=280980000000000004"
echo "   CANVAS_CLIENT_SECRET=your_secret"
echo "   CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback"
echo "   SESSION_SECRET=your_session_secret"
echo ""
echo "2. The Canvas connection button should now work without authentication errors"