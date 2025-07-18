#!/bin/bash

echo "=== Post-Deployment Testing ==="
echo "Testing Clean Okta Production Deployment"

# Test service status
echo "1. Service Status:"
sudo systemctl status canvas-course-generator.service --no-pager

# Test local endpoints
echo ""
echo "2. Local Endpoint Tests:"
echo "Health check:"
curl -s -o /dev/null -w "  HTTP %{http_code} - %{time_total}s\n" http://localhost:5000/health

echo "Root page:"
curl -s -o /dev/null -w "  HTTP %{http_code} - %{time_total}s\n" http://localhost:5000/

echo "Canvas API test:"
curl -s -o /dev/null -w "  HTTP %{http_code} - %{time_total}s\n" http://localhost:5000/api/test/canvas

# Test external HTTPS endpoints
echo ""
echo "3. External HTTPS Tests:"
echo "Health check:"
curl -s -o /dev/null -w "  HTTP %{http_code} - %{time_total}s\n" https://shell.dpvils.org/health

echo "Root page:"
curl -s -o /dev/null -w "  HTTP %{http_code} - %{time_total}s\n" https://shell.dpvils.org/

echo "Canvas API test:"
curl -s -o /dev/null -w "  HTTP %{http_code} - %{time_total}s\n" https://shell.dpvils.org/api/test/canvas

# Test Okta discovery endpoint
echo ""
echo "4. Okta Configuration Test:"
echo "Okta discovery endpoint:"
curl -s -o /dev/null -w "  HTTP %{http_code} - %{time_total}s\n" https://digitalpromise.okta.com/oauth2/default/.well-known/openid_configuration

# Check for errors in logs
echo ""
echo "5. Recent Error Logs:"
sudo journalctl -u canvas-course-generator.service --no-pager -n 20 | grep -i "error\|fail\|exception" || echo "  No errors found"

# Check environment configuration
echo ""
echo "6. Environment Configuration:"
if [ -f "/home/ubuntu/canvas-course-generator/.env" ]; then
    echo "  ✓ Environment file exists"
    echo "  Okta configuration:"
    grep -E "VITE_OKTA" /home/ubuntu/canvas-course-generator/.env || echo "  No Okta variables found"
    echo "  Canvas configuration:"
    grep -E "CANVAS_API_URL|CANVAS_API_TOKEN" /home/ubuntu/canvas-course-generator/.env || echo "  No Canvas variables found"
else
    echo "  ✗ Environment file missing"
fi

# Check build directory
echo ""
echo "7. Build Directory:"
if [ -d "/home/ubuntu/canvas-course-generator/dist" ]; then
    echo "  ✓ Build directory exists"
    echo "  Build files:"
    ls -la /home/ubuntu/canvas-course-generator/dist/ | head -5
else
    echo "  ✗ Build directory missing"
fi

# Test authentication flow
echo ""
echo "8. Authentication Flow Test:"
echo "Testing redirect to Okta (should get 302 or 200):"
curl -s -I https://shell.dpvils.org/ | head -3

echo ""
echo "=== Test Results Summary ==="
echo "✓ Service running: $(sudo systemctl is-active canvas-course-generator.service)"
echo "✓ Build deployed: $([ -d "/home/ubuntu/canvas-course-generator/dist" ] && echo "Yes" || echo "No")"
echo "✓ Environment configured: $([ -f "/home/ubuntu/canvas-course-generator/.env" ] && echo "Yes" || echo "No")"
echo "✓ External access: $(curl -s -o /dev/null -w "%{http_code}" https://shell.dpvils.org/health 2>/dev/null)"

echo ""
echo "=== Next Steps ==="
echo "1. Update .env with actual Canvas API token and database URL"
echo "2. Restart service: sudo systemctl restart canvas-course-generator.service"
echo "3. Test full authentication flow at https://shell.dpvils.org"
echo "4. Verify Canvas API functionality in dashboard"
echo ""
echo "Monitor logs: sudo journalctl -u canvas-course-generator.service -f"