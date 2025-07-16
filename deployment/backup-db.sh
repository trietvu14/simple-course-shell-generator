#!/bin/bash

# Database Backup Script for Canvas Course Generator
# Usage: ./backup-db.sh

set -e

# Configuration
DB_NAME="canvas_course_generator"
DB_USER="canvas_app"
BACKUP_DIR="/var/backups/canvas-course-generator/database"
LOG_FILE="/var/log/canvas-course-generator-backup.log"
RETENTION_DAYS=7

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

log "Starting database backup for $DB_NAME"

# Generate backup filename with timestamp
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$(date +%Y%m%d_%H%M%S).sql"

# Create database backup
log "Creating database backup..."
sudo -u postgres pg_dump -h localhost -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null || error "Failed to create database backup"

# Compress the backup
log "Compressing backup file..."
gzip "$BACKUP_FILE" || error "Failed to compress backup"
BACKUP_FILE="${BACKUP_FILE}.gz"

# Verify backup file exists and has content
if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    success "Database backup created successfully: $BACKUP_FILE ($BACKUP_SIZE)"
else
    error "Backup file is empty or doesn't exist"
fi

# Clean up old backups (keep only last N days)
log "Cleaning up old backups (keeping last $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete
success "Old backups cleaned up"

# List recent backups
log "Recent backups:"
ls -lah "$BACKUP_DIR"/${DB_NAME}_backup_*.sql.gz | tail -5 | tee -a "$LOG_FILE"

log "Database backup completed successfully"