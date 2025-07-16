#!/bin/bash

echo "=== Installing Production Dependencies ==="

APP_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Installing Node.js dependencies..."
cd "$APP_DIR"
sudo npm install --production=false

echo "2. Installing tsx specifically..."
sudo npm install tsx --save-dev

echo "3. Installing global tsx as backup..."
sudo npm install -g tsx

echo "4. Verifying installation..."
echo "Local tsx:"
ls -la "$APP_DIR/node_modules/.bin/tsx" || echo "Local tsx not found"

echo "Global tsx:"
which tsx || echo "Global tsx not found"

echo "NPX tsx:"
npx tsx --version || echo "NPX tsx not working"

echo "5. Checking package.json scripts..."
cat "$APP_DIR/package.json" | grep -A 5 -B 5 "scripts"

echo "6. Setting proper permissions..."
sudo chown -R ubuntu:ubuntu "$APP_DIR"
sudo chmod +x "$APP_DIR/node_modules/.bin/tsx" 2>/dev/null || echo "Could not set tsx permissions"

echo "7. Testing tsx execution..."
cd "$APP_DIR"
sudo -u ubuntu npx tsx --version || echo "TSX test failed"

echo "=== Dependencies Installation Complete ==="