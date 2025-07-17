#!/bin/bash

echo "=== Fixing Canvas OAuth Environment Variables ==="
echo ""

# Check current production environment
echo "1. Current production environment variables:"
grep -E "CANVAS_CLIENT_ID|CANVAS_CLIENT_SECRET|CANVAS_REDIRECT_URI|CANVAS_API_URL" /home/ubuntu/canvas-course-generator/.env

echo ""
echo "2. Updating Canvas OAuth environment variables..."

# Ensure all Canvas OAuth variables are properly set
cat > /tmp/canvas-oauth-vars.env << 'EOF'
# Canvas OAuth Configuration
CANVAS_CLIENT_ID=280980000000000004
CANVAS_CLIENT_SECRET=Gy3PtTYcXTFWZ7kn93DkBreWzfztYyxyUXer8RCcfWr4JQcLUW9K2BYcuu7LQVYa
CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
EOF

# Backup current .env
cp /home/ubuntu/canvas-course-generator/.env /home/ubuntu/canvas-course-generator/.env.backup

# Remove old Canvas OAuth variables
sed -i '/^CANVAS_CLIENT_ID=/d' /home/ubuntu/canvas-course-generator/.env
sed -i '/^CANVAS_CLIENT_SECRET=/d' /home/ubuntu/canvas-course-generator/.env
sed -i '/^CANVAS_REDIRECT_URI=/d' /home/ubuntu/canvas-course-generator/.env
sed -i '/^CANVAS_API_URL=/d' /home/ubuntu/canvas-course-generator/.env
sed -i '/^CANVAS_API_TOKEN=/d' /home/ubuntu/canvas-course-generator/.env

# Add updated Canvas OAuth variables
cat /tmp/canvas-oauth-vars.env >> /home/ubuntu/canvas-course-generator/.env

echo ""
echo "3. Updated environment variables:"
grep -E "CANVAS_CLIENT_ID|CANVAS_CLIENT_SECRET|CANVAS_REDIRECT_URI|CANVAS_API_URL|CANVAS_API_TOKEN" /home/ubuntu/canvas-course-generator/.env

echo ""
echo "4. Restarting Canvas Course Generator service..."
systemctl restart canvas-course-generator.service

sleep 5

echo ""
echo "5. Checking Canvas OAuth initialization in logs..."
journalctl -u canvas-course-generator.service -n 10 --no-pager | grep -A 3 "Canvas OAuth initialized"

echo ""
echo "6. Testing Canvas OAuth authorization endpoint..."
curl -s -o /dev/null -w "Authorization endpoint: %{http_code}\n" \
  "https://shell.dpvils.org/api/canvas/oauth/authorize"

echo ""
echo "=== Canvas OAuth Environment Fixed ==="
echo "✅ Canvas OAuth environment variables updated"
echo "✅ Service restarted with correct configuration"
echo "✅ Canvas OAuth should now initialize with proper client ID"
echo ""
echo "Next: Visit https://shell.dpvils.org and click 'Connect Canvas' to test OAuth flow"