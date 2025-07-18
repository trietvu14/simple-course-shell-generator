# Production Deployment Guide

## Overview
This guide covers deploying the Canvas Course Shell Generator with Okta SSO authentication to AWS EC2 at shell.dpvils.org.

## Prerequisites
- AWS EC2 instance running Ubuntu
- Domain shell.dpvils.org configured
- PostgreSQL database setup
- Nginx configured with SSL/TLS
- PM2 or systemd for process management

## Environment Variables Required
```bash
# Canvas Configuration
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=your_canvas_token

# Canvas OAuth (optional)
CANVAS_CLIENT_ID=280980000000000004
CANVAS_CLIENT_SECRET=your_canvas_oauth_secret
CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback

# Okta Authentication
OKTA_DOMAIN=digitalpromise.okta.com
OKTA_CLIENT_ID=your_okta_client_id
OKTA_CLIENT_SECRET=your_okta_client_secret
OKTA_REDIRECT_URI=https://shell.dpvils.org/callback
OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default

# Frontend Configuration
VITE_OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
VITE_OKTA_CLIENT_ID=your_okta_client_id
VITE_SIMPLE_AUTH=false

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/canvas_course_generator

# Session Management
SESSION_SECRET=your_secure_session_secret
```

## Deployment Steps

### 1. Build the Application
```bash
# Install dependencies
npm install

# Build the frontend
npm run build

# Build the backend
npm run build:server
```

### 2. Database Setup
```bash
# Run database migrations
npm run db:push
```

### 3. Process Management
```bash
# Using PM2
pm2 start ecosystem.config.cjs --env production

# Or using systemd
sudo systemctl enable canvas-course-generator
sudo systemctl start canvas-course-generator
```

### 4. Nginx Configuration
```nginx
server {
    listen 443 ssl;
    server_name shell.dpvils.org;
    
    ssl_certificate /etc/letsencrypt/live/shell.dpvils.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/shell.dpvils.org/privkey.pem;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Authentication Flow
1. **Okta SSO**: Primary authentication method for production users
2. **Simple Auth**: Fallback for testing and development
3. **Session Management**: Secure cookie-based sessions for Okta users

## Features Ready for Production
- ✅ Canvas API integration with personal access token
- ✅ Okta SSO authentication with Digital Promise
- ✅ Course shell creation and batch processing
- ✅ Account hierarchy management
- ✅ Real-time progress tracking
- ✅ Responsive UI with Canvas branding
- ✅ Error handling and logging
- ✅ Database session storage
- ✅ Dual authentication support

## Security Considerations
- All secrets stored in environment variables
- HTTPS/SSL required for production
- Secure cookie settings for Okta sessions
- Database connection security
- CORS configuration for production domain

## Monitoring
- PM2 process monitoring
- Application logs via winston
- Database query monitoring
- Canvas API rate limiting

## Backup and Recovery
- Database automated backups
- Environment variable backup
- Application code version control
- SSL certificate renewal automation