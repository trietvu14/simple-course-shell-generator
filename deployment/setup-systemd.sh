#!/bin/bash

# Setup systemd service for Canvas Course Shell Generator
# This replaces PM2 with a simpler systemd service

echo "🚀 Setting up Canvas Course Shell Generator with systemd..."

# Stop PM2 if running
echo "⏹️  Stopping PM2 processes..."
pm2 delete canvas-course-generator 2>/dev/null || true
pm2 kill 2>/dev/null || true

# Navigate to project directory
cd /home/ubuntu/course-shell-generator

# Update server/db.ts with PostgreSQL configuration
echo "🔧 Updating database configuration..."
cat > server/db.ts << 'EOF'
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from "@shared/schema";

if (!process.env.DATABASE_URL) {
  throw new Error(
    "DATABASE_URL must be set. Did you forget to provision a database?",
  );
}

export const pool = new Pool({ 
  connectionString: process.env.DATABASE_URL,
  ssl: false // Disable SSL for local PostgreSQL
});

export const db = drizzle(pool, { schema });
EOF

# Install PostgreSQL packages
echo "📦 Installing PostgreSQL packages..."
npm install pg @types/pg

# Build the application
echo "🔨 Building application..."
npm run build

# Set up database schema
echo "🗄️  Setting up database schema..."
npm run db:push || {
    echo "Drizzle migration failed, creating tables manually..."
    PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -f deployment/create-db-tables.sql
}

echo "✅ Verifying database tables..."
PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -c "\dt"

# Create systemd service file
echo "⚙️  Creating systemd service..."
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

# Environment variables
Environment=NODE_ENV=production
Environment=PORT=5000
Environment=DATABASE_URL=postgresql://postgres:DPVils25!@localhost:5432/canvas_course_generator
Environment=CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
Environment=CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
Environment=PGHOST=localhost
Environment=PGPORT=5432
Environment=PGUSER=postgres
Environment=PGPASSWORD=DPVils25!
Environment=PGDATABASE=canvas_course_generator

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

echo "🚀 Starting Canvas Course Shell Generator service..."
sudo systemctl enable canvas-course-generator
sudo systemctl start canvas-course-generator

# Check status
echo "📊 Checking service status..."
sudo systemctl status canvas-course-generator

# Wait a moment for startup
sleep 5

# Check logs
echo "📋 Checking application logs..."
sudo journalctl -u canvas-course-generator -n 20

# Test health endpoint
echo "🏥 Testing health endpoint..."
curl -s http://localhost:5000/health || echo "Health endpoint not responding"

# Test through nginx
echo "🌐 Testing through nginx..."
curl -s http://localhost/health || echo "Nginx proxy not responding"

echo "✅ Setup complete!"
echo ""
echo "📋 Useful commands:"
echo "  Check status: sudo systemctl status canvas-course-generator"
echo "  View logs: sudo journalctl -u canvas-course-generator -f"
echo "  Restart: sudo systemctl restart canvas-course-generator"
echo "  Stop: sudo systemctl stop canvas-course-generator"
echo ""
echo "🌐 Your Canvas Course Shell Generator should now be accessible at http://YOUR_EC2_PUBLIC_IP"
EOF

chmod +x setup-systemd.sh