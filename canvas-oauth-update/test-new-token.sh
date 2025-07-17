#!/bin/bash

echo "=== Testing New Canvas API Token ==="
echo ""

echo "1. Token info:"
echo "Length: ${#CANVAS_API_TOKEN}"
echo "First 15 chars: ${CANVAS_API_TOKEN:0:15}..."
echo "Last 10 chars: ...${CANVAS_API_TOKEN: -10}"

echo ""
echo "2. Testing Canvas API directly..."
curl -s -w "Status: %{http_code}\n" \
  -H "Authorization: Bearer $CANVAS_API_TOKEN" \
  "https://dppowerfullearning.instructure.com/api/v1/accounts" \
  -o /tmp/canvas_direct_test.json

if [ -f /tmp/canvas_direct_test.json ]; then
    echo "Response:"
    cat /tmp/canvas_direct_test.json | head -c 300
    echo ""
fi

echo ""
echo "3. Testing with curl verbose..."
curl -v -H "Authorization: Bearer $CANVAS_API_TOKEN" \
  "https://dppowerfullearning.instructure.com/api/v1/accounts" \
  2>&1 | head -20

echo ""
echo "4. Current environment variables:"
echo "CANVAS_API_URL: $CANVAS_API_URL"
echo "CANVAS_CLIENT_ID: $CANVAS_CLIENT_ID"