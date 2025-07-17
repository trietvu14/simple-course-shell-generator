#!/bin/bash

echo "=== Deploying Working Canvas Token to Production ==="
echo ""

# Create the update script for production
cat > /tmp/update-canvas-token.sh << 'EOF'
#!/bin/bash
# Update Canvas API token in production
sed -i 's/^CANVAS_API_TOKEN=.*/CANVAS_API_TOKEN='$CANVAS_API_TOKEN'/' /home/ubuntu/canvas-course-generator/.env
systemctl restart canvas-course-generator.service
echo "Canvas API token updated and service restarted"
EOF

# Make it executable
chmod +x /tmp/update-canvas-token.sh

echo "1. Testing current Canvas API token..."
curl -s -w "Canvas API Status: %{http_code}\n" \
  -H "Authorization: Bearer $CANVAS_API_TOKEN" \
  "https://dppowerfullearning.instructure.com/api/v1/accounts" \
  -o /tmp/canvas_response.json

if [ -f /tmp/canvas_response.json ]; then
    echo "Canvas API Response:"
    head -c 200 /tmp/canvas_response.json
    echo ""
fi

echo ""
echo "2. Production update commands:"
echo "scp /tmp/update-canvas-token.sh ubuntu@shell.dpvils.org:/tmp/"
echo "ssh ubuntu@shell.dpvils.org 'sudo /tmp/update-canvas-token.sh'"
echo ""
echo "3. Test production after update:"
echo "curl -s https://shell.dpvils.org/api/accounts | head -c 200"
echo ""
echo "=== Canvas Token Ready for Production Deployment ==="