# Missing Files for Canvas Connection Button

## Files That Need to Be Copied to Production

### 1. Canvas Connection Component
```bash
# Copy the main Canvas connection component
sudo cp canvas-oauth-update/client/src/components/canvas-connection.tsx \
    /home/ubuntu/canvas-course-generator/client/src/components/

# Copy the updated badge component
sudo cp canvas-oauth-update/client/src/components/ui/badge.tsx \
    /home/ubuntu/canvas-course-generator/client/src/components/ui/

# Copy the updated card component  
sudo cp canvas-oauth-update/client/src/components/ui/card.tsx \
    /home/ubuntu/canvas-course-generator/client/src/components/ui/

# Copy the updated dashboard page
sudo cp canvas-oauth-update/client/src/pages/dashboard.tsx \
    /home/ubuntu/canvas-course-generator/client/src/pages/
```

### 2. Server-side Canvas OAuth Files
```bash
# Copy Canvas OAuth manager
sudo cp canvas-oauth-update/server/canvas-oauth.ts \
    /home/ubuntu/canvas-course-generator/server/

# Copy updated routes with Canvas OAuth endpoints
sudo cp canvas-oauth-update/server/routes.ts \
    /home/ubuntu/canvas-course-generator/server/

# Copy updated storage with Canvas token methods
sudo cp canvas-oauth-update/server/storage.ts \
    /home/ubuntu/canvas-course-generator/server/
```

### 3. Database Schema Updates
```bash
# Copy updated schema with Canvas tokens table
sudo cp canvas-oauth-update/shared/schema.ts \
    /home/ubuntu/canvas-course-generator/shared/

# Push database changes
cd /home/ubuntu/canvas-course-generator
sudo -u ubuntu npm run db:push
```

### 4. Configuration Files
```bash
# Copy updated package.json (if dependencies changed)
sudo cp canvas-oauth-update/package.json \
    /home/ubuntu/canvas-course-generator/

# Install any new dependencies
cd /home/ubuntu/canvas-course-generator
sudo -u ubuntu npm install
```

### 5. Restart Application
```bash
# Restart the service
sudo systemctl restart canvas-course-generator.service

# Check status
sudo systemctl status canvas-course-generator.service
```

## Quick Copy Script

You can run this script to copy all necessary files:

```bash
#!/bin/bash
APP_DIR="/home/ubuntu/canvas-course-generator"
DEPLOY_DIR="canvas-oauth-update"

echo "Copying Canvas connection files..."

# Frontend files
sudo cp "$DEPLOY_DIR/client/src/components/canvas-connection.tsx" "$APP_DIR/client/src/components/"
sudo cp "$DEPLOY_DIR/client/src/components/ui/badge.tsx" "$APP_DIR/client/src/components/ui/"
sudo cp "$DEPLOY_DIR/client/src/components/ui/card.tsx" "$APP_DIR/client/src/components/ui/"
sudo cp "$DEPLOY_DIR/client/src/pages/dashboard.tsx" "$APP_DIR/client/src/pages/"

# Backend files
sudo cp "$DEPLOY_DIR/server/canvas-oauth.ts" "$APP_DIR/server/"
sudo cp "$DEPLOY_DIR/server/routes.ts" "$APP_DIR/server/"
sudo cp "$DEPLOY_DIR/server/storage.ts" "$APP_DIR/server/"

# Schema
sudo cp "$DEPLOY_DIR/shared/schema.ts" "$APP_DIR/shared/"

# Update database
cd "$APP_DIR"
sudo -u ubuntu npm run db:push

# Restart service
sudo systemctl restart canvas-course-generator.service

echo "Canvas connection files copied successfully!"
```

## What You'll See After Copying

1. **Canvas Connection Card** - A card at the top of the dashboard showing connection status
2. **"Connect Canvas" Button** - Button to start OAuth flow (requires Canvas developer key setup)
3. **Token Status** - Shows "Setup Required" until Canvas OAuth is configured
4. **Working Course Creation** - Course shells will continue working with static API token

The Canvas connection button provides a user-friendly interface for future OAuth setup while maintaining current functionality with the static API token.