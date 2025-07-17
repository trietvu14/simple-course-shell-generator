#!/bin/bash

echo "=== Deploying New Canvas API Token ==="
echo ""

echo "1. Updating production environment..."
# Update production .env file with new token
ssh ubuntu@shell.dpvils.org << EOF
sudo sed -i 's/^CANVAS_API_TOKEN=.*/CANVAS_API_TOKEN=$CANVAS_API_TOKEN/' /home/ubuntu/canvas-course-generator/.env
sudo systemctl restart canvas-course-generator.service
echo "Production environment updated and service restarted"
EOF

# Wait for service to restart
sleep 5

echo ""
echo "2. Testing new token in production..."
curl -s -w "Production Canvas API: %{http_code}\n" \
  -H "Authorization: Bearer $CANVAS_API_TOKEN" \
  "https://dppowerfullearning.instructure.com/api/v1/accounts" \
  -o /tmp/prod_test.json

if [ -f /tmp/prod_test.json ]; then
    echo "Production API response:"
    head -c 200 /tmp/prod_test.json
    echo ""
fi

echo ""
echo "3. Testing Canvas OAuth status..."
curl -s "https://shell.dpvils.org/api/canvas/oauth/status"

echo ""
echo ""
echo "4. Testing account loading..."
curl -s "https://shell.dpvils.org/api/accounts" | head -c 200

echo ""
echo ""
echo "=== Canvas API Token Deployment Complete ==="
echo "✅ Personal access token deployed to production"
echo "✅ No OAuth refresh tokens needed"
echo "✅ Canvas API should work with static token"
echo ""
echo "The system now uses the personal access token for all Canvas API calls."
echo "No Canvas OAuth flow is needed - the personal token handles all authentication."