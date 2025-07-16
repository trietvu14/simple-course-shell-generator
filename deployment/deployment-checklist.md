# Production Deployment Checklist

## Pre-Deployment Preparation

### 1. AWS Infrastructure
- [ ] EC2 instance launched (t3.medium or larger recommended)
- [ ] Security groups configured (SSH, HTTP, HTTPS)
- [ ] Elastic IP assigned (optional but recommended)
- [ ] Domain name configured (if using custom domain)
- [ ] DNS records pointing to EC2 instance

### 2. Local Preparation
- [ ] Code pushed to production branch
- [ ] All environment variables documented
- [ ] Database schema tested
- [ ] Canvas API credentials verified
- [ ] Okta application configured and tested

## Server Setup

### 3. Basic Server Configuration
- [ ] Ubuntu 22.04 LTS installed
- [ ] System updated (`sudo apt update && sudo apt upgrade`)
- [ ] Node.js 20 installed
- [ ] PM2 installed globally
- [ ] Nginx installed
- [ ] PostgreSQL installed and configured
- [ ] UFW firewall configured

### 4. Application Installation
- [ ] Repository cloned to `/var/www/canvas-course-generator`
- [ ] Dependencies installed (`npm install`)
- [ ] `.env.production` file created with actual values
- [ ] Database migrations run (`npm run db:push`)
- [ ] Application built (`npm run build`)

## Configuration Files

### 5. PM2 Configuration
- [ ] `ecosystem.config.js` copied and configured
- [ ] PM2 process started (`pm2 start ecosystem.config.js --env production`)
- [ ] PM2 startup script configured (`pm2 startup`)
- [ ] PM2 configuration saved (`pm2 save`)

### 6. Nginx Configuration
- [ ] Nginx site configuration created
- [ ] Domain names updated in configuration
- [ ] Site enabled (`ln -s /etc/nginx/sites-available/...`)
- [ ] Nginx configuration tested (`sudo nginx -t`)
- [ ] Nginx restarted

### 7. SSL Certificate
- [ ] Certbot installed
- [ ] SSL certificate obtained (`sudo certbot --nginx`)
- [ ] Auto-renewal tested (`sudo certbot renew --dry-run`)

## Security Setup

### 8. Security Configuration
- [ ] Strong passwords set for all accounts
- [ ] Database user permissions restricted
- [ ] UFW firewall enabled
- [ ] SSH key-based authentication configured
- [ ] Fail2ban installed (optional)
- [ ] Security headers configured in Nginx

### 9. Monitoring and Logging
- [ ] Health check endpoint responding (`/health`)
- [ ] PM2 monitoring configured
- [ ] Log rotation configured
- [ ] Database backup script installed
- [ ] Cron job for automated backups

## Testing

### 10. Functional Testing
- [ ] Application starts successfully
- [ ] Health check returns 200 OK
- [ ] Database connection working
- [ ] Canvas API integration working
- [ ] Okta authentication working
- [ ] All API endpoints responding
- [ ] Frontend loads correctly

### 11. Performance Testing
- [ ] Application responds within acceptable time
- [ ] Database queries optimized
- [ ] Static assets served efficiently
- [ ] Memory usage within limits
- [ ] PM2 cluster mode working

## Post-Deployment

### 12. Final Verification
- [ ] External access working (domain/IP)
- [ ] SSL certificate valid
- [ ] All features working end-to-end
- [ ] User authentication flow complete
- [ ] Course shell creation working
- [ ] Error handling working properly

### 13. Documentation and Access
- [ ] Production credentials documented securely
- [ ] Deployment scripts tested
- [ ] Rollback procedure documented
- [ ] Team access configured
- [ ] Monitoring dashboards set up

## Environment Variables Checklist

### Required Variables
- [ ] `NODE_ENV=production`
- [ ] `PORT=5000`
- [ ] `DATABASE_URL` (PostgreSQL connection string)
- [ ] `CANVAS_API_URL` (Canvas instance URL)
- [ ] `CANVAS_API_TOKEN` (Canvas API token)
- [ ] `OKTA_CLIENT_ID` (Okta application client ID)
- [ ] `OKTA_CLIENT_SECRET` (Okta application client secret)
- [ ] `OKTA_ISSUER` (Okta domain URL)

### Optional Variables
- [ ] `SESSION_SECRET` (for session security)
- [ ] `LOG_LEVEL` (logging level)
- [ ] `RATE_LIMIT_WINDOW_MS` (rate limiting)
- [ ] `RATE_LIMIT_MAX` (rate limiting)

## Common Issues to Check

### Application Issues
- [ ] PM2 process running (`pm2 status`)
- [ ] No port conflicts (`sudo lsof -i :5000`)
- [ ] Environment variables loaded correctly
- [ ] Database connection successful
- [ ] Sufficient memory available

### Network Issues
- [ ] Nginx running and configured correctly
- [ ] Firewall rules allow traffic
- [ ] DNS resolution working
- [ ] SSL certificate valid and trusted
- [ ] All ports accessible

### Authentication Issues
- [ ] Okta application configured correctly
- [ ] Redirect URIs match exactly
- [ ] API permissions granted
- [ ] Canvas API token valid
- [ ] Network access to external services

## Rollback Plan

### If Deployment Fails
1. [ ] Stop new PM2 processes
2. [ ] Restore previous application backup
3. [ ] Restart previous PM2 configuration
4. [ ] Verify health check passes
5. [ ] Rollback database if needed
6. [ ] Update DNS if required

## Monitoring Setup

### Health Checks
- [ ] Application health endpoint (`/health`)
- [ ] Database connectivity
- [ ] External API accessibility
- [ ] SSL certificate validity
- [ ] Disk space monitoring

### Alerts
- [ ] Application down alerts
- [ ] High memory usage alerts
- [ ] Database connection failures
- [ ] SSL certificate expiration
- [ ] High error rates

## Success Criteria

### Technical Success
- [ ] Application accessible via HTTPS
- [ ] All features working correctly
- [ ] Performance within acceptable limits
- [ ] Security measures in place
- [ ] Monitoring and logging active

### User Success
- [ ] Users can authenticate with Okta
- [ ] Course shell creation working
- [ ] Account selection functioning
- [ ] Progress tracking working
- [ ] Error messages helpful

---

**Deployment Date**: ___________
**Deployed By**: ___________
**Verified By**: ___________
**Sign-off**: ___________