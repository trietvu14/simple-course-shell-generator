#!/bin/bash

echo "🔍 Diagnosing 500 Internal Server Error"
echo "========================================"

# Check systemd service status
echo "1. Checking systemd service status..."
sudo systemctl status canvas-course-generator --no-pager

echo -e "\n2. Checking service logs (last 20 lines)..."
sudo journalctl -u canvas-course-generator -n 20 --no-pager

echo -e "\n3. Checking if application is listening on port 5000..."
sudo netstat -tlnp | grep :5000

echo -e "\n4. Checking nginx status..."
sudo systemctl status nginx --no-pager

echo -e "\n5. Checking nginx error logs (last 10 lines)..."
sudo tail -n 10 /var/log/nginx/error.log

echo -e "\n6. Testing direct connection to application..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:5000/health

echo -e "\n7. Checking database connection..."
psql -h localhost -U postgres -d canvas_course_generator -c "SELECT 1;" 2>/dev/null && echo "Database connection: OK" || echo "Database connection: FAILED"

echo -e "\n8. Checking environment variables in systemd service..."
sudo systemctl show canvas-course-generator --property=Environment

echo -e "\n9. Checking if dist/index.js exists..."
ls -la /home/ubuntu/course-shell-generator/dist/index.js

echo -e "\n10. Testing nginx proxy..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/health

echo -e "\n🔧 Diagnostic complete. Check the output above for issues."