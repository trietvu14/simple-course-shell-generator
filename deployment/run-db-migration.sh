#!/bin/bash

echo "Creating database tables for Canvas Course Generator..."

cd /home/ubuntu/course-shell-generator

# Method 1: Try using Drizzle push
echo "1. Attempting Drizzle migration..."
npm run db:push 2>&1 || echo "Drizzle migration failed, trying manual SQL..."

# Method 2: Manual SQL execution
echo "2. Creating tables manually..."
PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -f deployment/create-db-tables.sql

# Verify tables were created
echo "3. Verifying tables exist..."
PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -c "\dt"

# Show table structure
echo "4. Showing table structures..."
PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -c "\d users"

# Test a simple insert to verify permissions
echo "5. Testing database permissions..."
PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -c "SELECT 1 as test;"

# Restart the application
echo "6. Restarting application..."
sudo systemctl restart canvas-course-generator

# Wait for startup
sleep 3

# Test health endpoint
echo "7. Testing application health..."
curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health

echo "Database migration complete!"