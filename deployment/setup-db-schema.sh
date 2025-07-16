#!/bin/bash

echo "Setting up database schema for Canvas Course Generator..."

cd /home/ubuntu/course-shell-generator

# Install dependencies if needed
echo "1. Installing dependencies..."
npm ci

# Run database migration to create tables
echo "2. Creating database tables..."
npm run db:push

# Verify tables were created
echo "3. Verifying database tables..."
PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -c "\dt"

# Test database connection with new schema
echo "4. Testing database schema..."
PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"

# Restart the application service
echo "5. Restarting application service..."
sudo systemctl restart canvas-course-generator

# Wait for service to start
sleep 3

# Test health endpoint
echo "6. Testing health endpoint..."
curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health

# Test through nginx
echo "7. Testing through nginx..."
curl -s http://localhost/health | jq . 2>/dev/null || curl -s http://localhost/health

echo "Database setup complete!"