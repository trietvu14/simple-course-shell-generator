#!/bin/bash

echo "=== Quick Test of Production Fix ==="

echo "1. Service Status:"
sudo systemctl is-active canvas-course-generator.service

echo "2. Local Tests:"
curl -s -o /dev/null -w "Health: %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: %{http_code}\n" http://localhost:5000/

echo "3. External Tests:"
curl -s -o /dev/null -w "HTTPS Health: %{http_code}\n" https://shell.dpvils.org/health
curl -s -o /dev/null -w "HTTPS Root: %{http_code}\n" https://shell.dpvils.org/

echo "4. Recent Logs:"
sudo journalctl -u canvas-course-generator.service --no-pager -n 5

echo ""
echo "Expected Results:"
echo "- Service: active"
echo "- Local Health: 200"
echo "- HTTPS Health: 200"
echo "- No module resolution errors in logs"