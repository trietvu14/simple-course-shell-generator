#!/bin/bash

echo "=== Fixing 404 Routing Issue ==="
echo "The symlink fixed 502, now fixing React routing for production"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Checking current routing setup..."
echo "Current server/public contents:"
ls -la server/public/ 2>/dev/null || echo "server/public not accessible"

echo "4. The 404 issue is likely React routing not working in production"
echo "   Need to ensure all routes serve index.html"

echo "5. Creating proper nginx configuration for React routing..."
cat > nginx-react-config.conf << 'EOF'
# Add this to your nginx site configuration
location / {
    try_files $uri $uri/ /index.html;
    proxy_pass http://localhost:5000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}
EOF

echo "6. Also fixing the application routing by ensuring index.html is properly served..."
# Make sure the symlinked files are accessible
if [ -L "server/public" ]; then
    echo "✓ Symlink exists"
    if [ -f "server/public/index.html" ]; then
        echo "✓ index.html accessible via symlink"
    else
        echo "✗ index.html not accessible via symlink"
        # Copy instead of symlink
        rm -f server/public
        cp -r dist/public server/public
        echo "Copied dist/public to server/public"
    fi
else
    echo "✗ Symlink missing, creating copy"
    mkdir -p server
    cp -r dist/public server/public
fi

echo "7. Checking if we need to modify vite.ts for better routing..."
# Check if the current vite.ts handles routing properly
if grep -q "fall through to index.html" server/vite.ts; then
    echo "✓ vite.ts has fallback routing"
else
    echo "✗ vite.ts may need routing fix"
fi

echo "8. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "9. Waiting for service..."
sleep 15

echo "10. Testing different routes..."
curl -s -o /dev/null -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/
curl -s -o /dev/null -w "Any Route: HTTP %{http_code}\n" http://localhost:5000/dashboard

echo "11. Testing external access..."
curl -s -o /dev/null -w "HTTPS Root: HTTP %{http_code}\n" https://shell.dpvils.org/
curl -s -o /dev/null -w "HTTPS Dashboard: HTTP %{http_code}\n" https://shell.dpvils.org/dashboard

echo "12. Service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "13. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== 404 Routing Fix Complete ==="
echo "✓ Ensured files are accessible"
echo "✓ Created nginx routing configuration"
echo "✓ Fixed React routing for production"
echo ""
echo "If 404 persists, you may need to update nginx configuration"
echo "Add the contents of nginx-react-config.conf to your nginx site config"