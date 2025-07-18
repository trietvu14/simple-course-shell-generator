# Production 404 Fix - Deployment Guide

## Issue Analysis

The production server is experiencing 404 errors because:

1. **Wrong Service Mode**: The systemd service is running `npm run dev` (development) instead of `npm run start` (production)
2. **Missing Build**: The application needs to be built for production using `npm run build`
3. **Static File Serving**: The server needs to serve the built React application properly

## Fix Instructions

### Step 1: Upload Files to Server

Upload the entire `production-deployment-fix/` directory to your production server.

### Step 2: Run the Comprehensive Fix

On the production server, run:

```bash
./fix-404-production.sh
```

This script will:
- Stop the current service
- Create a backup of the current deployment
- Copy updated files
- Install dependencies
- Build the application for production
- Create a proper production systemd service
- Start the service with the production build

### Step 3: Update Nginx Configuration (Optional)

If you want to optimize the nginx configuration for better routing:

```bash
./update-nginx.sh
```

## Expected Results

After running the fix:

1. **Service Status**: The service should be running with `node dist/index.js` instead of `tsx server/index.ts`
2. **Application Access**: https://shell.dpvils.org should load the React application
3. **API Endpoints**: All `/api/*` endpoints should work correctly
4. **Okta Authentication**: Users should be redirected to Digital Promise Okta login

## Verification Steps

1. Check service status:
   ```bash
   sudo systemctl status canvas-course-generator.service
   ```

2. Test application:
   ```bash
   curl https://shell.dpvils.org
   curl https://shell.dpvils.org/api/health
   ```

3. Check logs:
   ```bash
   sudo journalctl -u canvas-course-generator.service -f
   ```

## Key Changes Made

### Production Service Configuration
- Changed from development mode (`npm run dev`) to production mode (`node dist/index.js`)
- Added proper environment variable loading
- Configured automatic restart on failure

### Application Build
- Runs `npm run build` to create production-optimized files
- Creates `dist/` directory with bundled server and client code
- Optimizes assets for production serving

### Nginx Configuration
- All routes now properly proxy to the Node.js application
- Handles React Router correctly
- Optimizes static asset serving
- Adds security headers

## Troubleshooting

If the fix doesn't work:

1. **Check Build Output**: Ensure `dist/` directory exists and contains `index.js`
2. **Verify Environment**: Check that `.env` file has all required variables
3. **Test Locally**: Run `npm run build && npm run start` locally first
4. **Check Logs**: Monitor `sudo journalctl -u canvas-course-generator.service -f`

## Environment Variables Required

Ensure these are in your `.env` file:

```
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=your_token_here
DATABASE_URL=your_database_url_here
VITE_OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
VITE_OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7
VITE_SIMPLE_AUTH=false
```

## Post-Deployment Testing

1. **Access Application**: https://shell.dpvils.org
2. **Test Okta Login**: Should redirect to Digital Promise Okta
3. **Test Canvas API**: Account loading should work
4. **Test Course Creation**: Full workflow should function

The fix addresses the root cause of the 404 errors by properly building and serving the React application in production mode.