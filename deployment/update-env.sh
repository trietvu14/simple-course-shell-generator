#!/bin/bash

echo "Updating .env file with correct database credentials..."

# Update the .env file with the correct database user
cat > /home/ubuntu/course-shell-generator/.env << 'EOF'
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://canvas_app:DPVils25!@localhost:5432/canvas_course_generator
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
PGHOST=localhost
PGPORT=5432
PGUSER=canvas_app
PGPASSWORD=DPVils25!
PGDATABASE=canvas_course_generator
EOF

# Set proper permissions
chmod 600 /home/ubuntu/course-shell-generator/.env
chown ubuntu:ubuntu /home/ubuntu/course-shell-generator/.env

echo ".env file updated successfully!"