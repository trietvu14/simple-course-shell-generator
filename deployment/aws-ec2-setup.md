# AWS EC2 Production Deployment Guide

## Prerequisites

1. AWS Account with EC2 access
2. Domain name (optional, for custom domain)
3. SSL certificate (Let's Encrypt or AWS Certificate Manager)

## EC2 Instance Setup

### 1. Launch EC2 Instance

```bash
# Recommended instance type: t3.medium or larger
# Operating System: Ubuntu 22.04 LTS
# Security Groups: Allow HTTP (80), HTTPS (443), SSH (22)
```

### 2. Connect to Instance

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 3. Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 for process management
sudo npm install -g pm2

# Install Nginx for reverse proxy
sudo apt install -y nginx

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install certbot for SSL (if using custom domain)
sudo apt install -y certbot python3-certbot-nginx
```

## Database Setup

### 1. Configure PostgreSQL

```bash
# Switch to postgres user
sudo -u postgres psql

# Create database and user
CREATE DATABASE canvas_course_generator;
CREATE USER canvas_app WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE canvas_course_generator TO canvas_app;
\q
```

### 2. Configure PostgreSQL for external connections

```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/14/main/postgresql.conf
# Set: listen_addresses = 'localhost'

# Edit pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf
# Add: local   canvas_course_generator   canvas_app   md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

## Application Deployment

### 1. Clone and Setup Application

```bash
# Navigate to web directory
cd /var/www

# Clone your repository (replace with your actual repo)
sudo git clone <your-repo-url> canvas-course-generator
sudo chown -R $USER:$USER canvas-course-generator
cd canvas-course-generator

# Install dependencies
npm install

# Build the application
npm run build
```

### 2. Environment Configuration

```bash
# Create production environment file
cp .env.example .env.production

# Edit with production values
nano .env.production
```

### 3. Database Migration

```bash
# Run database migrations
npm run db:push
```

## Process Management with PM2

### 1. Create PM2 Configuration

```bash
# Create ecosystem file
nano ecosystem.config.js
```

### 2. Start Application

```bash
# Start with PM2
pm2 start ecosystem.config.js --env production

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
```

## Nginx Configuration

### 1. Create Nginx Configuration

```bash
# Create site configuration
sudo nano /etc/nginx/sites-available/canvas-course-generator
```

### 2. Enable Site

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/canvas-course-generator /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

## SSL Certificate (Optional)

### 1. Obtain SSL Certificate

```bash
# Using Let's Encrypt (replace with your domain)
sudo certbot --nginx -d your-domain.com
```

### 2. Auto-renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Cron job is automatically created
```

## Security Configuration

### 1. Firewall Setup

```bash
# Install UFW
sudo apt install ufw

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### 2. Security Headers

```bash
# Add security headers to Nginx configuration
# (Already included in the nginx config file)
```

## Monitoring and Logs

### 1. Application Logs

```bash
# View PM2 logs
pm2 logs canvas-course-generator

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 2. System Monitoring

```bash
# Install htop for system monitoring
sudo apt install htop

# Monitor PM2 processes
pm2 monit
```

## Backup Strategy

### 1. Database Backup

```bash
# Create backup script
sudo nano /usr/local/bin/backup-db.sh
sudo chmod +x /usr/local/bin/backup-db.sh

# Add to crontab for daily backups
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/backup-db.sh
```

### 2. Application Backup

```bash
# Create application backup
tar -czf canvas-app-backup-$(date +%Y%m%d).tar.gz /var/www/canvas-course-generator
```

## Deployment Script

Create an automated deployment script for updates:

```bash
# Create deployment script
nano deploy.sh
chmod +x deploy.sh
```

## Health Checks

### 1. Application Health

```bash
# Check if application is running
pm2 status

# Check application health endpoint
curl http://localhost:5000/health
```

### 2. Database Health

```bash
# Check database connection
sudo -u postgres psql -c "SELECT 1;" canvas_course_generator
```

## Troubleshooting

### Common Issues

1. **Port 5000 already in use**
   - Check: `sudo lsof -i :5000`
   - Kill process: `sudo kill <PID>`

2. **Database connection errors**
   - Check PostgreSQL status: `sudo systemctl status postgresql`
   - Check database logs: `sudo tail -f /var/log/postgresql/postgresql-14-main.log`

3. **Nginx errors**
   - Check configuration: `sudo nginx -t`
   - Check logs: `sudo tail -f /var/log/nginx/error.log`

## Performance Optimization

### 1. Node.js Optimization

```bash
# Increase Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=4096"
```

### 2. Database Optimization

```bash
# Optimize PostgreSQL settings in postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
```

### 3. Nginx Optimization

```bash
# Enable gzip compression
# Enable caching for static assets
# (Already included in nginx config)
```

## Updates and Maintenance

### 1. Application Updates

```bash
# Run deployment script
./deploy.sh

# Or manual update
git pull origin main
npm install
npm run build
pm2 restart canvas-course-generator
```

### 2. System Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Node.js if needed
sudo npm install -g n
sudo n stable
```

This guide provides a comprehensive setup for production deployment on AWS EC2. Adjust configurations based on your specific requirements and security policies.