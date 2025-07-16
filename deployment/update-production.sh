#!/bin/bash

# Production Update Script for Canvas Course Shell Generator
# This script updates the database configuration and rebuilds the application

echo "🚀 Starting production update..."

# Navigate to project directory
cd /home/ubuntu/course-shell-generator

# Stop PM2 process
echo "⏹️  Stopping PM2 process..."
pm2 delete canvas-course-generator

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

# Update ecosystem.config.cjs with correct environment variables
echo "⚙️  Updating PM2 configuration..."
cat > ecosystem.config.cjs << 'EOF'
module.exports = {
  apps: [{
    name: 'canvas-course-generator',
    script: './dist/index.js',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 5000,
      DATABASE_URL: 'postgresql://postgres:DPVils25!@localhost:5432/canvas_course_generator',
      CANVAS_API_URL: 'https://dppowerfullearning.instructure.com/api/v1',
      CANVAS_API_TOKEN: '28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG',
      PGHOST: 'localhost',
      PGPORT: '5432',
      PGUSER: 'postgres',
      PGPASSWORD: 'DPVils25!',
      PGDATABASE: 'canvas_course_generator'
    },
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    min_uptime: '10s',
    max_restarts: 10,
    restart_delay: 4000
  }]
};
EOF

# Start PM2 with updated configuration
echo "🚀 Starting PM2 process..."
pm2 start ecosystem.config.cjs

# Check status
echo "📊 Checking PM2 status..."
pm2 status

# Wait a moment for startup
sleep 5

# Check logs
echo "📋 Checking application logs..."
pm2 logs canvas-course-generator --lines 10

# Test health endpoint
echo "🏥 Testing health endpoint..."
curl -s http://localhost:5000/health || echo "Health endpoint not responding"

# Test through nginx
echo "🌐 Testing through nginx..."
curl -s http://localhost/health || echo "Nginx proxy not responding"

echo "✅ Production update complete!"
echo "Your Canvas Course Shell Generator should now be accessible at http://YOUR_EC2_PUBLIC_IP"
EOF