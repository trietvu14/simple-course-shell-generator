#!/bin/bash

# Load environment variables from .env.production
if [ -f .env.production ]; then
    export $(cat .env.production | grep -v ^# | xargs)
fi

# Start the application with PM2
pm2 start ecosystem.config.cjs --env production

echo "Application started with PM2"
echo "Check status with: pm2 status"
echo "Check logs with: pm2 logs canvas-course-generator"