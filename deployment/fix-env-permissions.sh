#!/bin/bash

echo "Fixing .env file permissions and systemd service..."

# Check current .env file status
echo "1. Checking .env file status:"
ls -la /home/ubuntu/course-shell-generator/.env

# Fix permissions on .env file
echo "2. Setting correct permissions on .env file:"
sudo chown ubuntu:ubuntu /home/ubuntu/course-shell-generator/.env
sudo chmod 644 /home/ubuntu/course-shell-generator/.env

# Verify .env file contents
echo "3. Verifying .env file contents:"
cat /home/ubuntu/course-shell-generator/.env

# Create a new systemd service with explicit environment variables
echo "4. Creating systemd service with explicit environment variables:"
sudo tee /etc/systemd/system/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator
After=network.target
After=postgresql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/course-shell-generator
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

# Explicit environment variables
Environment=NODE_ENV=production
Environment=PORT=5000
Environment=DATABASE_URL=postgresql://canvas_app:DPVils25!@localhost:5432/canvas_course_generator
Environment=CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
Environment=CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
Environment=PGHOST=localhost
Environment=PGPORT=5432
Environment=PGUSER=canvas_app
Environment=PGPASSWORD=DPVils25!
Environment=PGDATABASE=canvas_course_generator

[Install]
WantedBy=multi-user.target
EOF

echo "5. Reloading systemd and restarting service:"
sudo systemctl daemon-reload
sudo systemctl restart canvas-course-generator

echo "6. Checking service status:"
sudo systemctl status canvas-course-generator --no-pager

echo "7. Testing health endpoint:"
sleep 3
curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health

echo "8. Testing through nginx:"
curl -s http://localhost/health | jq . 2>/dev/null || curl -s http://localhost/health