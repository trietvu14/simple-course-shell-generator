#!/bin/bash

echo "=== Copying Essential Files for Canvas OAuth Update ==="

# Check if target directory is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <target-directory>"
    echo "Example: $0 /tmp/canvas-oauth-update"
    exit 1
fi

TARGET_DIR="$1"
echo "Creating deployment package in: $TARGET_DIR"

# Create target directory
mkdir -p "$TARGET_DIR"

# Copy server files
echo "Copying server files..."
mkdir -p "$TARGET_DIR/server"
cp server/canvas-oauth.ts "$TARGET_DIR/server/"
cp server/routes.ts "$TARGET_DIR/server/"
cp server/storage.ts "$TARGET_DIR/server/"
cp server/db.ts "$TARGET_DIR/server/"
cp server/index.ts "$TARGET_DIR/server/"
cp server/health.ts "$TARGET_DIR/server/"

# Copy shared files
echo "Copying shared files..."
mkdir -p "$TARGET_DIR/shared"
cp shared/schema.ts "$TARGET_DIR/shared/"

# Copy client files
echo "Copying client files..."
cp -r client/ "$TARGET_DIR/"

# Copy configuration files
echo "Copying configuration files..."
cp package.json "$TARGET_DIR/"
cp tsconfig.json "$TARGET_DIR/"
cp vite.config.ts "$TARGET_DIR/"
cp tailwind.config.ts "$TARGET_DIR/"
cp postcss.config.js "$TARGET_DIR/"
cp drizzle.config.ts "$TARGET_DIR/"

# Copy deployment files
echo "Copying deployment files..."
cp ec2-production/setup-canvas-oauth.md "$TARGET_DIR/"
cp ec2-production/update-canvas-oauth.sh "$TARGET_DIR/"

# Create sample .env file
echo "Creating sample .env file..."
cat > "$TARGET_DIR/.env.sample" << 'EOF'
# Database
DATABASE_URL=your_database_url
PGHOST=your_pg_host
PGPORT=5432
PGUSER=your_pg_user
PGPASSWORD=your_pg_password
PGDATABASE=your_pg_database

# Canvas OAuth (NEW - REQUIRED)
CANVAS_CLIENT_ID=your_canvas_client_id
CANVAS_CLIENT_SECRET=your_canvas_client_secret
CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback
CANVAS_API_URL=https://your-canvas-domain.com/api/v1

# Session (NEW - REQUIRED)
SESSION_SECRET=your_secure_session_secret

# Canvas API (Legacy - can be removed after OAuth setup)
CANVAS_API_TOKEN=your_canvas_api_token
EOF

# Create README for deployment
cat > "$TARGET_DIR/DEPLOYMENT_README.md" << 'EOF'
# Canvas OAuth Deployment Package

## Files Included
- ✅ Updated server files with Canvas OAuth
- ✅ Updated database schema
- ✅ Complete React frontend
- ✅ Configuration files
- ✅ Deployment scripts

## Deployment Steps

1. **Upload to EC2 server**:
   ```bash
   scp -r * ubuntu@your-server:/home/ubuntu/canvas-course-generator/
   ```

2. **Update environment variables**:
   ```bash
   cp .env.sample .env
   # Edit .env with your actual values
   ```

3. **Run deployment**:
   ```bash
   ./update-canvas-oauth.sh
   ```

4. **Follow setup guide**:
   - Read `setup-canvas-oauth.md`
   - Configure Canvas developer key
   - Test OAuth flow

## What's New
- Canvas OAuth 2.0 with automatic token refresh
- Database schema for token storage
- Enhanced error handling and security
- Production-ready deployment scripts

Total package size: ~265KB (much smaller than full repository)
EOF

echo "✅ Deployment package created successfully!"
echo "📁 Location: $TARGET_DIR"
echo "📋 Files included:"
find "$TARGET_DIR" -type f | sort
echo ""
echo "🚀 Next steps:"
echo "1. Copy this folder to your EC2 server"
echo "2. Update .env file with your Canvas credentials"
echo "3. Run ./update-canvas-oauth.sh"
echo "4. Follow setup-canvas-oauth.md for Canvas developer key setup"