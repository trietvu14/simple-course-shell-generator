# URGENT: 502 Bad Gateway Error Fix

## Problem Diagnosis
The 502 error is caused by a Node.js module resolution issue in the production build. The application fails to start because it can't find required modules.

## Root Cause
- Production build compilation creates incorrect module paths
- ES modules not resolving properly in the built output
- Node.js process exits with `ERR_MODULE_NOT_FOUND` error

## Solution
Use `tsx` to run TypeScript directly in production, bypassing the build compilation issues.

## Deployment Instructions

### 1. Upload Files
Upload the entire `production-deployment/` directory to your production server.

### 2. Run the Fix
```bash
ssh ubuntu@shell.dpvils.org
cd /path/to/production-deployment
./deploy-502-fix.sh
```

### 3. What the Fix Does
- Stops the failing service
- Installs `tsx` globally for production use
- Updates systemd service to run `tsx server/index.ts` directly
- Starts the service with proper restart configuration
- Tests the application endpoints

### 4. Expected Results
- Service starts without module resolution errors
- Application responds on port 5000
- HTTPS access works through nginx proxy
- Okta authentication flows properly

## Key Changes Made

### Before (Failing)
```bash
ExecStart=/usr/bin/node dist/index.js
```

### After (Fixed)
```bash
ExecStart=/usr/bin/npx tsx server/index.ts
```

## Verification Commands

```bash
# Check service status
sudo systemctl status canvas-course-generator.service

# Test local endpoints
curl http://localhost:5000/health
curl http://localhost:5000/

# Test external access
curl https://shell.dpvils.org/health
curl https://shell.dpvils.org/

# Monitor logs
sudo journalctl -u canvas-course-generator.service -f
```

## If Issues Persist

1. Check environment variables in `.env`
2. Verify Canvas API token is set
3. Ensure database URL is correct
4. Run `./diagnose-502.sh` for detailed analysis

This fix resolves the module resolution issue that was causing the 502 Bad Gateway error by running TypeScript directly instead of relying on the problematic build output.