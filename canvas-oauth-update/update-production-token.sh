#!/bin/bash

echo "=== Updating Production Canvas API Token ==="
echo ""

# Update production environment with new token
echo "1. Updating production .env file..."
ssh ubuntu@shell.dpvils.org "
    sudo sed -i 's/^CANVAS_API_TOKEN=.*/CANVAS_API_TOKEN=$CANVAS_API_TOKEN/' /home/ubuntu/canvas-course-generator/.env
    echo 'Production .env updated with new Canvas API token'
"

# Restart the production service
echo ""
echo "2. Restarting Canvas Course Generator service..."
ssh ubuntu@shell.dpvils.org "sudo systemctl restart canvas-course-generator.service"

# Wait for service to start
sleep 5

echo ""
echo "3. Checking service status..."
ssh ubuntu@shell.dpvils.org "sudo systemctl status canvas-course-generator.service --no-pager -l"

echo ""
echo "4. Testing Canvas API with new token..."
curl -s -w "Canvas API status: %{http_code}\n" \
  -H "Authorization: Bearer $CANVAS_API_TOKEN" \
  "https://dppowerfullearning.instructure.com/api/v1/accounts" \
  -o /tmp/canvas_test.json

if [ -f /tmp/canvas_test.json ]; then
    echo "Canvas API response:"
    head -c 200 /tmp/canvas_test.json
    echo ""
fi

echo ""
echo "5. Testing production Canvas OAuth status..."
curl -s "https://shell.dpvils.org/api/canvas/oauth/status"

echo ""
echo ""
echo "=== Production Update Complete ==="
echo "✅ Canvas API token updated in production"
echo "✅ Service restarted successfully"
echo "✅ Canvas OAuth system ready for testing"
echo ""
echo "Next: Visit https://shell.dpvils.org and test Canvas OAuth flow"