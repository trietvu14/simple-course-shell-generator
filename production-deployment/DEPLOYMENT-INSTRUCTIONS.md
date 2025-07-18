# Production Deployment Instructions

## Quick Start

1. **Upload this entire directory** to your production server
2. **Run the deployment script**: `./deploy-clean-okta-final.sh`
3. **Configure environment**: Update `.env` with your actual tokens
4. **Restart service**: `sudo systemctl restart canvas-course-generator.service`
5. **Test**: Visit https://shell.dpvils.org

## What This Deployment Includes

### ✅ Fixes Applied
- **OAuth Error Fixed**: Removed conflicting simple authentication
- **404 Error Fixed**: Proper production build configuration
- **Clean Authentication**: Only Okta authentication, no mixed systems
- **Production Ready**: Built with `npm run build` for production serving

### 📦 Package Contents
- `deploy-clean-okta-final.sh` - Main deployment script
- `post-deployment-test.sh` - Testing script
- `README-DEPLOYMENT.md` - Detailed documentation
- Complete application source code (client/, server/, shared/)
- Production configuration files

### 🔧 Key Changes
- Removed all simple authentication code
- Simplified authentication middleware to Okta-only
- Disabled Canvas OAuth to prevent conflicts
- Configured proper production build process

## Expected Results

After deployment:
- **Service Status**: Running with production build
- **Authentication**: Digital Promise Okta SSO working
- **Application**: No 404 errors, proper React routing
- **Canvas API**: Working with personal access token
- **Performance**: Optimized production build

## Commands to Run

```bash
# 1. Deploy application
./deploy-clean-okta-final.sh

# 2. Test deployment
./post-deployment-test.sh

# 3. Monitor logs
sudo journalctl -u canvas-course-generator.service -f

# 4. Check service status
sudo systemctl status canvas-course-generator.service
```

## Environment Variables to Configure

Update `/home/ubuntu/canvas-course-generator/.env`:

```bash
# Replace with your actual Canvas API token
CANVAS_API_TOKEN=your_actual_canvas_token

# Replace with your actual database URL
DATABASE_URL=your_actual_database_url
```

## Verification Checklist

- [ ] Service is running: `sudo systemctl is-active canvas-course-generator.service`
- [ ] Build directory exists: `ls -la /home/ubuntu/canvas-course-generator/dist/`
- [ ] Environment configured: `cat /home/ubuntu/canvas-course-generator/.env`
- [ ] External access works: `curl https://shell.dpvils.org/health`
- [ ] Okta redirect works: Visit https://shell.dpvils.org in browser
- [ ] Canvas API works: Test in dashboard after login

This deployment resolves all authentication conflicts and provides a clean, production-ready Canvas Course Shell Generator.