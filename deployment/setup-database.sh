#!/bin/bash

echo "Setting up PostgreSQL database for Canvas Course Generator..."

# Switch to postgres user and create database and user
sudo -u postgres psql << 'EOF'
-- Create database
CREATE DATABASE canvas_course_generator;

-- Create user with password
CREATE USER canvas_user WITH PASSWORD 'DPVils25!';

-- Grant all privileges on database
GRANT ALL PRIVILEGES ON DATABASE canvas_course_generator TO canvas_user;

-- Connect to the database and grant schema privileges
\c canvas_course_generator
GRANT ALL ON SCHEMA public TO canvas_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO canvas_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO canvas_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO canvas_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO canvas_user;

-- Exit
\q
EOF

echo "Database setup complete!"
echo "Testing connection..."
psql -h localhost -U canvas_user -d canvas_course_generator -c "SELECT 1;" || echo "Connection test failed"