#!/bin/bash

echo "=== Checking Production Server File Structure ==="

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Checking if application directory exists..."
if [ -d "$TARGET_DIR" ]; then
    echo "✓ Application directory exists"
    cd "$TARGET_DIR"
else
    echo "✗ Application directory missing"
    exit 1
fi

echo ""
echo "2. Checking main directory contents..."
ls -la

echo ""
echo "3. Checking dist directory..."
if [ -d "dist" ]; then
    echo "✓ dist directory exists"
    echo "Contents:"
    ls -la dist/
    if [ -f "dist/index.html" ]; then
        echo "✓ dist/index.html exists"
    else
        echo "✗ dist/index.html missing"
    fi
else
    echo "✗ dist directory missing"
fi

echo ""
echo "4. Checking public directory..."
if [ -d "public" ]; then
    echo "✓ public directory exists"
    echo "Contents:"
    ls -la public/
    if [ -f "public/index.html" ]; then
        echo "✓ public/index.html exists"
    else
        echo "✗ public/index.html missing - THIS IS THE ISSUE"
    fi
else
    echo "✗ public directory missing"
fi

echo ""
echo "5. Checking what the server expects..."
echo "According to server/vite.ts, the serveStatic function looks for:"
echo "path.resolve(import.meta.dirname, 'public')"
echo "Which resolves to: server/public OR the main public directory"

echo ""
echo "6. Current service status..."
sudo systemctl status canvas-course-generator.service --no-pager -l

echo ""
echo "7. Recent error logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Analysis Complete ==="
echo "The issue is likely:"
echo "1. Missing index.html in the public directory"
echo "2. Server trying to serve static files from empty public directory"
echo "3. Application crashing because it can't find the required files"
echo ""
echo "Run ./fix-missing-files.sh to create the required files"