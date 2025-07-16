# Quick Start Guide for AWS EC2 Deployment

## Prerequisites
- AWS EC2 instance running Ubuntu 22.04
- Domain name pointing to your EC2 instance (optional)
- Your Canvas API credentials
- Your Okta credentials

## Step 1: Initial Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2, Nginx, and PostgreSQL
sudo npm install -g pm2
sudo apt install -y nginx postgresql postgresql-contrib git

# Configure PostgreSQL
sudo -u postgres psql
CREATE DATABASE canvas_course_generator;
CREATE USER canvas_app WITH ENCRYPTED PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE canvas_course_generator TO canvas_app;
\q
```

## Step 2: Deploy Application

```bash
# Clone repository to /var/www
cd /var/www
sudo git clone <your-repo-url> canvas-course-generator
sudo chown -R $USER:$USER canvas-course-generator
cd canvas-course-generator

# Install dependencies
npm install

# Copy environment configuration
cp deployment/.env.production.example .env.production

# Edit with your actual credentials
nano .env.production
```

## Step 3: Configure Environment Variables

Edit `.env.production` with your actual values:

```env
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://canvas_app:your_secure_password_here@localhost:5432/canvas_course_generator
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=your_canvas_api_token
OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7
OKTA_CLIENT_SECRET=Ez5CUFKEF2-MdAthRXS6EteDzs8sO28iUMDhHyFETDtIaVt1XufExidViy8uGGRz
OKTA_ISSUER=https://digitalpromise.okta.com
```

## Step 4: Build and Start Application

```bash
# Build the application
npm run build

# Run database migrations
npm run db:push

# Copy PM2 configuration
cp deployment/ecosystem.config.js .

# Start application with PM2
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

## Step 5: Configure Nginx

```bash
# Copy Nginx configuration
sudo cp deployment/nginx-config /etc/nginx/sites-available/canvas-course-generator

# Edit with your domain name
sudo nano /etc/nginx/sites-available/canvas-course-generator

# Enable the site
sudo ln -s /etc/nginx/sites-available/canvas-course-generator /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Step 6: SSL Certificate (Optional)

```bash
# Install certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
sudo certbot --nginx -d your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

## Step 7: Configure Firewall

```bash
# Install and configure UFW
sudo apt install ufw
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

## Step 8: Setup Backups

```bash
# Copy backup scripts
sudo cp deployment/backup-db.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup-db.sh

# Add to crontab for daily backups
sudo crontab -e
# Add this line:
0 2 * * * /usr/local/bin/backup-db.sh
```

## Step 9: Test Deployment

```bash
# Check application health
curl http://localhost:5000/health

# Check external access (if using domain)
curl https://your-domain.com/health

# Check PM2 status
pm2 status
pm2 logs canvas-course-generator
```

## Step 10: Future Deployments

```bash
# Make deployment script executable
chmod +x deployment/deploy.sh

# Run deployment
./deployment/deploy.sh
```

## Troubleshooting

### Application won't start
```bash
# Check logs
pm2 logs canvas-course-generator

# Check environment variables
pm2 env 0

# Restart application
pm2 restart canvas-course-generator
```

### Database connection errors
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check database connection
sudo -u postgres psql -c "SELECT 1;" canvas_course_generator
```

### Nginx errors
```bash
# Check Nginx configuration
sudo nginx -t

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

## Monitoring

```bash
# Monitor PM2 processes
pm2 monit

# View application logs
pm2 logs canvas-course-generator

# Check system resources
htop
```

## Security Considerations

1. **Change default passwords** in `.env.production`
2. **Configure firewall** to only allow necessary ports
3. **Regular updates** with `sudo apt update && sudo apt upgrade`
4. **Monitor logs** for suspicious activity
5. **Backup regularly** and test restore procedures

## Performance Optimization

1. **Increase PM2 instances** in `ecosystem.config.js`
2. **Configure PostgreSQL** for your workload
3. **Enable Nginx caching** for static assets
4. **Monitor memory usage** and adjust as needed

Your Canvas Course Shell Generator is now ready for production use!