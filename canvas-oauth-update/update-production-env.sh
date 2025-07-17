#!/bin/bash

echo "=== Updating Production Canvas OAuth Environment ==="

# Update the .env file with the correct redirect URI
echo "1. Updating Canvas OAuth redirect URI in .env..."
sed -i 's|CANVAS_REDIRECT_URI=https://shell.dpvils.org/oauth/callback|CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback|g' /home/ubuntu/canvas-course-generator/.env

# Verify the change
echo "2. Verifying environment variables..."
grep "CANVAS_REDIRECT_URI" /home/ubuntu/canvas-course-generator/.env

# Restart the service to apply changes
echo "3. Restarting Canvas Course Generator service..."
systemctl restart canvas-course-generator.service

# Wait for service to start
sleep 5

# Check service status
echo "4. Checking service status..."
systemctl status canvas-course-generator.service --no-pager

echo ""
echo "5. Checking Canvas OAuth configuration in logs..."
journalctl -u canvas-course-generator.service -n 5 --no-pager | grep -E "(Canvas OAuth|clientId|canvasUrl|redirectUri)"

echo ""
echo "=== Canvas OAuth Update Complete ==="
echo "✅ Redirect URI updated to: https://shell.dpvils.org/api/canvas/oauth/callback"
echo "✅ Service restarted with new configuration"
echo ""
echo "Next steps:"
echo "1. Update Canvas developer key redirect URI to: https://shell.dpvils.org/api/canvas/oauth/callback"
echo "2. Test Canvas OAuth flow by clicking 'Connect Canvas' button"
echo "3. Complete Canvas authorization to store OAuth tokens"