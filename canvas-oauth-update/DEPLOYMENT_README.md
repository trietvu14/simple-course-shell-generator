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
- **Canvas OAuth 2.0** with automatic token refresh
- **Canvas Connection UI** - New "Connect Canvas" button and status display
- **Token Status Display** - Shows expiry time and connection state
- **Database schema** for token storage
- **Enhanced error handling** and security
- **Production-ready deployment scripts**
- **Updated with 5-user authentication system**:
  - admin / DPVils25!
  - sbritwum / DPVils25!
  - acampbell / DPVils25!
  - ewest / DPVils25!
  - mparkinson / DPVils25!

Total package size: ~265KB (much smaller than full repository)
