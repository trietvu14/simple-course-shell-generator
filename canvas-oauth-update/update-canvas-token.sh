#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <new_canvas_token>"
    echo "Example: $0 28098~NewTokenHere"
    exit 1
fi

NEW_TOKEN="$1"

echo "=== Updating Canvas API Token ==="
echo ""

# Update production environment
echo "1. Updating production environment..."
ssh ubuntu@shell.dpvils.org "
    sudo sed -i 's/^CANVAS_API_TOKEN=.*/CANVAS_API_TOKEN=$NEW_TOKEN/' /home/ubuntu/canvas-course-generator/.env
    sudo systemctl restart canvas-course-generator.service
    echo 'Production environment updated and service restarted'
"

# Update local Replit environment
echo ""
echo "2. Updating Replit environment..."
sed -i "s/^CANVAS_API_TOKEN=.*/CANVAS_API_TOKEN=$NEW_TOKEN/" .env
echo "Replit environment updated"

# Test the new token
echo ""
echo "3. Testing new Canvas API token..."
sleep 5
curl -s -w "Canvas API test: %{http_code}\n" \
  -H "Authorization: Bearer $NEW_TOKEN" \
  "https://dppowerfullearning.instructure.com/api/v1/accounts" \
  -o /tmp/canvas_token_test.json

if [ -f /tmp/canvas_token_test.json ]; then
    echo "Canvas API response:"
    head -c 200 /tmp/canvas_token_test.json
    echo ""
fi

echo ""
echo "4. Testing production Canvas OAuth..."
curl -s "https://shell.dpvils.org/api/canvas/oauth/status" | head -c 100

echo ""
echo ""
echo "=== Canvas Token Update Complete ==="
echo "✅ Production environment updated"
echo "✅ Replit environment updated"
echo "✅ Canvas API token refreshed"
echo ""
echo "Next: Visit https://shell.dpvils.org and test Canvas OAuth flow"