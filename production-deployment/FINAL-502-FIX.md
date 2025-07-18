# FINAL 502 Bad Gateway Fix

## Root Cause Identified
The application fails with this error:
```
Error: Could not find the build directory: /home/ubuntu/canvas-course-generator/public
```

The `serveStatic` function in `server/vite.ts` line 74 is looking for a `public` directory that doesn't exist in production.

## The Problem
1. Application runs in production mode (`NODE_ENV=production`)
2. Code calls `serveStatic(app)` which looks for `public` directory
3. Directory doesn't exist, application crashes
4. Service fails to start, causing 502 Bad Gateway

## Solution Options

### Option 1: Build Directory Fix (Recommended)
Run `./fix-build-directory.sh` to:
- Create the required build directory
- Run `npm run build` to generate static files
- Start the service properly

### Option 2: Simple Server (Immediate Fix)
Run `./deploy-simple-server.sh` to:
- Use a standalone server that doesn't require build directory
- Bypass the vite.ts dependency completely
- Get the service running immediately

### Option 3: Environment Override
Change the service to run in development mode:
```bash
Environment=NODE_ENV=development
```

## Recommended Deployment Steps

1. **Upload files** to production server
2. **Run the simple server fix** first to get it working:
   ```bash
   ./deploy-simple-server.sh
   ```
3. **Verify it works** at https://shell.dpvils.org
4. **Later, upgrade** to full build with `./fix-build-directory.sh`

## What Each Fix Does

### Simple Server Fix
- Creates `production-server-simple.js` - standalone Express server
- No dependency on build directory or vite.ts
- Serves health check, API endpoints, and fallback HTML
- Guaranteed to work without build issues

### Build Directory Fix
- Creates the required `public` directory
- Runs `npm run build` to generate static files
- Keeps the original application architecture
- More complete solution but requires successful build

The simple server fix will get you running immediately, then you can upgrade to the full build later.