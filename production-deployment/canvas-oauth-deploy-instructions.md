# Canvas OAuth Production Deployment Instructions

## Current Issue
The Canvas OAuth system is failing because the deployment hasn't been applied to production. The Canvas OAuth manager constructor isn't properly initialized with storage, causing token storage failures.

## Solution
Deploy the Canvas OAuth fix from the `canvas-oauth-update` directory to production.

## Deployment Steps

### 1. Upload the Canvas OAuth Update Package
```bash
# From your local machine, upload the fix to the server
scp -r canvas-oauth-update ubuntu@shell.dpvils.org:/tmp/
```

### 2. Deploy the Canvas OAuth Fix
```bash
# SSH to the production server
ssh ubuntu@shell.dpvils.org

# Navigate to the deployment package
cd /tmp/canvas-oauth-update

# Make the deployment script executable
chmod +x deploy-canvas-connection.sh

# Run the deployment script
sudo ./deploy-canvas-connection.sh
```

### 3. Verify the Deployment
```bash
# Check service status
sudo systemctl status canvas-course-generator.service

# Check recent logs
sudo journalctl -u canvas-course-generator.service -f
```

## What This Fixes
- **Canvas OAuth Manager Constructor**: Now properly accepts storage instance
- **Token Storage**: OAuth tokens will be stored in PostgreSQL database
- **Error Handling**: Improved token cleanup and fallback mechanisms
- **Logging**: Enhanced debugging output for OAuth flow

## Expected Result
After deployment:
1. Canvas OAuth status should show proper configuration
2. OAuth flow should complete without authentication errors
3. Tokens should be stored in the database
4. Account loading should work with OAuth tokens

## Files Updated
- `server/canvas-oauth.ts` - Fixed constructor with storage instance
- `server/routes.ts` - Updated OAuth callback handling
- `server/storage.ts` - Enhanced token storage methods
- `shared/schema.ts` - Updated database schema

The Canvas OAuth system should work end-to-end after this deployment.