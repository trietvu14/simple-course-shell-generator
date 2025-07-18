#!/bin/bash

echo "=== Fixing Path Mismatch for Static Files ==="
echo "The application looks for server/public but files are in dist/public"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Current file structure:"
echo "dist/public contents:"
ls -la dist/public/ 2>/dev/null || echo "dist/public not found"
echo ""

echo "4. The issue: serveStatic looks for server/public but files are in dist/public"
echo "   Creating symlink to fix path mismatch..."

# Create server directory if it doesn't exist
mkdir -p server

# Remove existing public directory in server if it exists
rm -rf server/public

# Create symlink from server/public to dist/public
ln -s ../dist/public server/public

echo "5. Verifying symlink..."
ls -la server/public 2>/dev/null || echo "Symlink creation failed"

echo "6. Alternative approach - copy files to expected location..."
# Also copy files to the expected location as backup
cp -r dist/public server/public-backup 2>/dev/null || echo "Copy failed"

echo "7. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "8. Waiting for service..."
sleep 15

echo "9. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "10. Testing application..."
curl -s -o /dev/null -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/

echo "11. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Path Fix Complete ==="
echo "Created symlink from server/public to dist/public"
echo "This should resolve the path mismatch issue"