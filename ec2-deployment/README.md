# EC2 Deployment Instructions

## Files included:
- Complete React application with working authentication
- Production server configuration
- Automatic installation script

## To deploy:

1. Upload this entire directory to your EC2 instance:
   ```bash
   scp -r ec2-deployment/ ubuntu@your-ec2-ip:/home/ubuntu/
   ```

2. SSH into your EC2 instance:
   ```bash
   ssh ubuntu@your-ec2-ip
   ```

3. Run the installation script:
   ```bash
   cd /home/ubuntu/ec2-deployment
   chmod +x install-on-ec2.sh
   ./install-on-ec2.sh
   ```

4. The application will be available at https://shell.dpvils.org

## What this deployment does:
- Stops the current simple-server.js version
- Installs the full React application
- Starts a production server that runs the development server (includes both API and React)
- Creates a systemd service for automatic startup
- Updates the database schema

## To check status:
```bash
sudo systemctl status canvas-course-generator
sudo journalctl -u canvas-course-generator -f
```
