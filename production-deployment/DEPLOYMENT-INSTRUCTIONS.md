# Canvas Course Shell Generator - Complete Deployment

## Current Status
- Test page is running at shell.dpvils.org
- Need to deploy complete Canvas Course Shell Generator application

## Deployment Steps

### 1. Run the deployment script
```bash
./deploy-complete-canvas-app.sh
```

### 2. What this script does
- Stops the current service
- Replaces the test page with the complete Canvas application
- Updates server configuration with full API endpoints
- Restarts the service with complete functionality

### 3. What files get updated
- `dist/public/index.html` - Complete Canvas Course Shell Generator interface
- `production-react-server.js` - Server with Canvas API endpoints

### 4. What files remain unchanged
- `.env` - Environment variables and secrets
- Systemd service configuration
- Nginx configuration
- SSL certificates
- All other configuration files

### 5. Expected result
After deployment, https://shell.dpvils.org will show:
- Complete Canvas Course Shell Generator dashboard
- Digital Promise authentication
- Course creation forms and tools
- Canvas account selection interface
- Progress tracking and status updates

## No directory replacement needed
The script works within your existing directory structure and only updates the necessary application files.