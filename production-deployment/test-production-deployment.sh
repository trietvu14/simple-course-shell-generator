#!/bin/bash

echo "=== Testing Production Deployment ==="

# Check if running on production server
if [ -f "/etc/systemd/system/canvas-course-generator.service" ]; then
    echo "✓ Running on production server"
    
    echo "1. Checking service status..."
    sudo systemctl status canvas-course-generator.service --no-pager
    
    echo ""
    echo "2. Checking if application is responding..."
    curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health
    
    echo ""
    echo "3. Checking recent logs..."
    sudo journalctl -u canvas-course-generator.service --no-pager -n 20
    
    echo ""
    echo "4. Testing Okta configuration..."
    if curl -s http://localhost:5000 | grep -q "okta"; then
        echo "✓ Okta configuration detected"
    else
        echo "! Okta configuration not detected in response"
    fi
    
else
    echo "! Not running on production server"
    echo "This script should be run on the production server after deployment"
fi

echo ""
echo "=== Production URLs ==="
echo "Application: https://shell.dpvils.org"
echo "Health Check: https://shell.dpvils.org/health"
echo "Okta Login: https://digitalpromise.okta.com/oauth2/default"
echo ""
echo "=== Testing Instructions ==="
echo "1. Open https://shell.dpvils.org in browser"
echo "2. Should redirect to Digital Promise Okta login"
echo "3. After authentication, should redirect back to application"
echo "4. Check browser console for any errors"
echo "5. Test Canvas account loading functionality"