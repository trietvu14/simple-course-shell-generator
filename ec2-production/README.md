# Canvas Course Shell Generator - EC2 Deployment

This package contains everything needed to deploy the Canvas Course Shell Generator with simple authentication to your EC2 instance.

## Quick Deployment

1. Upload this entire repository to your EC2 instance
2. Navigate to the repository directory
3. Run the deployment script:
   ```bash
   cd ec2-production
   ./deploy-complete.sh
   ```

## What's Included

- **Simple Authentication**: Login with admin / P@ssword01
- **Canvas API Integration**: Uses your existing Canvas API token
- **Database Support**: PostgreSQL configuration
- **Systemd Service**: Proper service management
- **Production Ready**: Optimized for EC2 deployment

## Files Overview

- `canvas-course-generator.service` - Systemd service configuration
- `start-production.cjs` - Production startup script
- `.env` - Environment variables
- `deploy-complete.sh` - Complete deployment script

## Post-Deployment

- **Access**: https://shell.dpvils.org
- **Login**: admin / P@ssword01
- **Logs**: `sudo journalctl -u canvas-course-generator.service -f`
- **Restart**: `sudo systemctl restart canvas-course-generator.service`

## Features

- Create Canvas course shells in bulk
- Select from Canvas account hierarchy
- Real-time progress tracking
- Batch management
- Recent activity history

## Troubleshooting

If the service fails to start:
1. Check logs: `sudo journalctl -u canvas-course-generator.service -f`
2. Verify permissions: `sudo chown -R ubuntu:ubuntu /home/ubuntu/canvas-course-generator`
3. Restart service: `sudo systemctl restart canvas-course-generator.service`

The application bypasses all Okta authentication issues and allows immediate testing of Canvas course creation functionality.