# EC2 Production Deployment

## Quick Start

### Option 1: GitHub Clone (Recommended)
1. **SSH to EC2** and clone from GitHub:
   ```bash
   ssh ubuntu@your-ec2-ip
   git clone https://github.com/yourusername/canvas-course-generator.git
   cd canvas-course-generator/canvas-deployment
   chmod +x deploy.sh
   ./deploy.sh
   ```

### Option 2: Direct Upload
1. **Upload to EC2**: Transfer this entire `canvas-deployment` folder to your EC2 instance
   ```bash
   scp -r canvas-deployment ubuntu@your-ec2-ip:/tmp/canvas-deployment
   ```

2. **Run deployment script** on EC2:
   ```bash
   ssh ubuntu@your-ec2-ip
   cd /tmp/canvas-deployment
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Configure environment**: Edit `/home/ubuntu/canvas-course-generator/.env` with your actual values

4. **Restart service**:
   ```bash
   sudo systemctl restart canvas-course-generator
   ```

## Environment Variables Needed

- `CANVAS_API_TOKEN`: Your Canvas personal access token
- `OKTA_CLIENT_ID`: Your Okta application client ID
- `OKTA_CLIENT_SECRET`: Your Okta application client secret
- `DATABASE_URL`: Your PostgreSQL connection string
- `SESSION_SECRET`: Random secure string for session encryption

## Verification

After deployment, check:
- Service status: `sudo systemctl status canvas-course-generator`
- Logs: `sudo journalctl -u canvas-course-generator -f`
- Website: https://shell.dpvils.org

## Authentication

- **Okta SSO**: Primary authentication for Digital Promise users
- **Simple Auth**: Fallback (admin/DPVils25!)