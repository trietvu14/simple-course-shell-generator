#!/bin/bash

# Canvas Course Generator Deployment Script
# Usage: ./deploy.sh

set -e

APP_NAME="canvas-course-generator"
APP_DIR="/var/www/$APP_NAME"
BACKUP_DIR="/var/backups/$APP_NAME"
LOG_FILE="/var/log/$APP_NAME-deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as correct user
if [ "$USER" != "ubuntu" ] && [ "$USER" != "root" ]; then
    error "This script should be run as ubuntu or root user"
fi

log "Starting deployment of $APP_NAME"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create logs directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Backup current application
if [ -d "$APP_DIR" ]; then
    log "Creating backup of current application..."
    BACKUP_NAME="$APP_NAME-backup-$(date +%Y%m%d-%H%M%S)"
    sudo cp -r "$APP_DIR" "$BACKUP_DIR/$BACKUP_NAME"
    success "Backup created: $BACKUP_DIR/$BACKUP_NAME"
fi

# Navigate to application directory
cd "$APP_DIR" || error "Cannot navigate to $APP_DIR"

# Stop the application
log "Stopping application..."
pm2 stop "$APP_NAME" || warning "Application was not running"

# Pull latest changes
log "Pulling latest changes from repository..."
git pull origin main || error "Failed to pull latest changes"

# Install dependencies
log "Installing dependencies..."
npm ci --production || error "Failed to install dependencies"

# Build the application
log "Building application..."
npm run build || error "Failed to build application"

# Run database migrations
log "Running database migrations..."
npm run db:push || error "Failed to run database migrations"

# Start the application
log "Starting application..."
pm2 start ecosystem.config.js --env production || error "Failed to start application"

# Reload PM2 to apply changes
log "Reloading PM2 configuration..."
pm2 reload "$APP_NAME" || error "Failed to reload PM2"

# Test if application is running
log "Testing application health..."
sleep 5
if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    success "Application is running successfully"
else
    error "Application health check failed"
fi

# Restart Nginx to ensure proper configuration
log "Restarting Nginx..."
sudo systemctl reload nginx || error "Failed to restart Nginx"

# Clean up old backups (keep last 5)
log "Cleaning up old backups..."
cd "$BACKUP_DIR"
ls -t | tail -n +6 | xargs -r rm -rf
success "Old backups cleaned up"

# Final health check
log "Performing final health check..."
if curl -f https://$(hostname -f)/health > /dev/null 2>&1; then
    success "Deployment completed successfully! Application is accessible."
else
    warning "Application is running but HTTPS health check failed. Check SSL configuration."
fi

log "Deployment completed at $(date)"
log "View logs with: pm2 logs $APP_NAME"
log "Monitor application with: pm2 monit"

success "Deployment finished successfully!"