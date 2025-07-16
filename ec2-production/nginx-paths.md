# Nginx Paths for Canvas Course Shell Generator

## Key Paths:

### Application Directory
- **Root Path**: `/home/ubuntu/canvas-course-generator`
- **Node.js Server**: Runs on `http://127.0.0.1:5000`

### Nginx Configuration Files
- **Main Config**: `/etc/nginx/nginx.conf`
- **Site Config**: `/etc/nginx/sites-available/canvas-course-generator`
- **Enabled Site**: `/etc/nginx/sites-enabled/canvas-course-generator`

### SSL Certificates (if using Let's Encrypt)
- **Certificate**: `/etc/letsencrypt/live/shell.dpvils.org/fullchain.pem`
- **Private Key**: `/etc/letsencrypt/live/shell.dpvils.org/privkey.pem`

### Log Files
- **Nginx Access**: `/var/log/nginx/access.log`
- **Nginx Error**: `/var/log/nginx/error.log`
- **App Logs**: `sudo journalctl -u canvas-course-generator.service -f`

## Configuration Summary:

Since this is a Node.js application, nginx acts as a **reverse proxy** rather than serving static files. The configuration:

1. **Receives requests** on port 80/443
2. **Forwards them** to your Node.js app on port 5000
3. **Handles SSL termination** and security headers
4. **Serves responses** back to the client

No traditional "document root" is needed - nginx proxies everything to your Node.js application running on port 5000.