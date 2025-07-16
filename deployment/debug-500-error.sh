#!/bin/bash

echo "Debugging 500 Internal Server Error"
echo "==================================="

# Check service status
echo "1. Service Status:"
sudo systemctl status canvas-course-generator --no-pager

# Check recent logs
echo -e "\n2. Recent Service Logs:"
sudo journalctl -u canvas-course-generator -n 20 --no-pager

# Test direct connection to application
echo -e "\n3. Testing Direct Connection to Application:"
curl -v http://localhost:5000/health 2>&1

# Check if nginx is running
echo -e "\n4. Nginx Status:"
sudo systemctl status nginx --no-pager

# Test nginx proxy
echo -e "\n5. Testing Nginx Proxy:"
curl -v http://localhost/health 2>&1

# Check nginx error logs
echo -e "\n6. Nginx Error Logs:"
sudo tail -n 10 /var/log/nginx/error.log

# Test database connection manually
echo -e "\n7. Manual Database Connection Test:"
PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -c "SELECT 1;" 2>&1

# Check if application process is running
echo -e "\n8. Application Process:"
ps aux | grep node | grep -v grep

# Check port usage
echo -e "\n9. Port Usage:"
sudo netstat -tlnp | grep -E ':(5000|80|443)'

echo -e "\n10. Testing Raw HTTP Request:"
echo -e "GET /health HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 5000

echo -e "\nDebug complete."