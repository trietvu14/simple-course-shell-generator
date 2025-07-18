#!/bin/bash

echo "=== Diagnosing 502 Bad Gateway Error ==="

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Current service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo ""
echo "2. Recent error logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 30

echo ""
echo "3. Checking application directory..."
if [ -d "$TARGET_DIR" ]; then
    echo "✓ Application directory exists"
    cd "$TARGET_DIR"
    
    echo "Directory contents:"
    ls -la
    
    echo ""
    echo "4. Checking build directory..."
    if [ -d "dist" ]; then
        echo "✓ Build directory exists"
        echo "Build contents:"
        ls -la dist/
        
        if [ -f "dist/index.js" ]; then
            echo "✓ index.js exists"
            echo "File size: $(stat -c%s dist/index.js) bytes"
        else
            echo "✗ index.js missing"
        fi
    else
        echo "✗ Build directory missing"
    fi
    
    echo ""
    echo "5. Checking package.json..."
    if [ -f "package.json" ]; then
        echo "✓ package.json exists"
        echo "Scripts section:"
        cat package.json | jq '.scripts' 2>/dev/null || grep -A 10 '"scripts"' package.json
    else
        echo "✗ package.json missing"
    fi
    
    echo ""
    echo "6. Checking node_modules..."
    if [ -d "node_modules" ]; then
        echo "✓ node_modules exists"
        echo "Size: $(du -sh node_modules 2>/dev/null || echo 'unknown')"
    else
        echo "✗ node_modules missing"
    fi
    
    echo ""
    echo "7. Checking environment file..."
    if [ -f ".env" ]; then
        echo "✓ .env file exists"
        echo "Environment variables (excluding secrets):"
        grep -v "TOKEN\|SECRET\|PASSWORD" .env || echo "No non-secret variables found"
    else
        echo "✗ .env file missing"
    fi
    
else
    echo "✗ Application directory does not exist"
fi

echo ""
echo "8. Testing local connection..."
curl -s -o /dev/null -w "Port 5000: HTTP %{http_code}\n" http://localhost:5000/health 2>/dev/null || echo "Port 5000: Connection failed"

echo ""
echo "9. Checking nginx configuration..."
if [ -f "/etc/nginx/sites-available/shell.dpvils.org" ]; then
    echo "✓ Nginx config exists"
    echo "Upstream configuration:"
    grep -A 5 -B 5 "proxy_pass" /etc/nginx/sites-available/shell.dpvils.org
else
    echo "✗ Nginx config missing"
fi

echo ""
echo "10. Testing nginx..."
sudo nginx -t 2>&1 || echo "Nginx test failed"

echo ""
echo "=== Diagnosis Complete ==="
echo "The 502 error is likely caused by:"
echo "1. Module resolution error in production build"
echo "2. Missing or incorrect build output"
echo "3. Node.js process not starting properly"
echo ""
echo "Recommended fixes:"
echo "1. Run ./fix-502-error.sh to use tsx directly"
echo "2. Run ./alternative-build-fix.sh for simple server"
echo "3. Check logs for specific module errors"