# Canvas Course Shell Generator - Simple Deployment Instructions

## Current Issue
The systemd service is failing because it cannot find the required files in the expected locations.

## Root Cause
The deployment script is trying to copy files from the wrong source directory structure.

## Solution Steps

### 1. Upload Repository
Upload the **entire repository** to your EC2 instance at `/home/ubuntu/canvas-course-generator`

### 2. Fix the Deployment
Run the fix script:
```bash
cd /home/ubuntu/canvas-course-generator/ec2-production
chmod +x fix-deployment.sh
./fix-deployment.sh
```

### 3. Manual Setup (if script fails)
If the script fails, do these steps manually:

```bash
# Navigate to app directory
cd /home/ubuntu/canvas-course-generator

# Copy production files
cp ec2-production/.env .env
cp ec2-production/start-production.cjs start-production.cjs
sudo cp ec2-production/canvas-course-generator.service /etc/systemd/system/

# Set permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/canvas-course-generator
chmod +x start-production.cjs

# Install dependencies
npm install

# Configure systemd
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service
sudo systemctl start canvas-course-generator.service

# Check status
sudo systemctl status canvas-course-generator.service
```

### 4. Verify Service
Check that the service is running:
```bash
sudo systemctl status canvas-course-generator.service
sudo journalctl -u canvas-course-generator.service -f
```

### 5. Setup Nginx (Optional)
If you want to set up nginx proxy:
```bash
cd /home/ubuntu/canvas-course-generator/ec2-production
chmod +x setup-nginx.sh
./setup-nginx.sh
```

## Expected Result
- Service running on port 5000
- Application accessible at https://shell.dpvils.org
- Login with: admin / P@ssword01
- Full Canvas course creation functionality

## Files Created
- `/home/ubuntu/canvas-course-generator/.env` - Environment variables
- `/home/ubuntu/canvas-course-generator/start-production.cjs` - Startup script
- `/etc/systemd/system/canvas-course-generator.service` - Systemd service

## Troubleshooting
- **Service won't start**: Check logs with `sudo journalctl -u canvas-course-generator.service -f`
- **Files not found**: Ensure the entire repository is at `/home/ubuntu/canvas-course-generator`
- **Permission denied**: Run `sudo chown -R ubuntu:ubuntu /home/ubuntu/canvas-course-generator`