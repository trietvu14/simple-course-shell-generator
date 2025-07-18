# Canvas Course Shell Generator - Deployment Guide

## Current Status
- **Environment**: Production-ready with AWS EC2 deployment configuration
- **Authentication**: Okta integration implemented
- **Database**: PostgreSQL with Drizzle ORM
- **Build System**: Vite + ESBuild for optimal performance
- **Process Management**: Systemd service (replacing PM2)

## Recent Updates (July 15, 2025)

### Database Configuration
- Updated from Neon serverless to PostgreSQL
- Fixed database connection issues for local PostgreSQL
- Added proper SSL configuration for local databases

### Deployment Architecture
- Created systemd service for process management
- Replaced PM2 with more reliable systemd service
- Added comprehensive environment variable configuration
- Implemented proper logging and restart policies

### Files Structure
```
deployment/
├── setup-systemd.sh              # Systemd setup script
├── canvas-course-generator.service # Systemd service file
├── update-production.sh          # Production update script
├── nginx-config                  # Nginx proxy configuration
├── server-db.ts                  # Updated database configuration
├── aws-ec2-setup.md              # EC2 deployment guide
└── quick-start.md                # Quick deployment guide
```

## Production Deployment Commands

### Initial Setup
```bash
# Setup systemd service (includes database migration)
chmod +x deployment/setup-systemd.sh
./deployment/setup-systemd.sh
```

### Database Migration (if needed separately)
```bash
# Run database migration
npm run db:push

# Or create tables manually if migration fails
PGPASSWORD=DPVils25! psql -h localhost -U canvas_app -d canvas_course_generator -f deployment/create-db-tables.sql
```

### Service Management
```bash
# Check status
sudo systemctl status canvas-course-generator

# View logs
sudo journalctl -u canvas-course-generator -f

# Restart service
sudo systemctl restart canvas-course-generator
```

### Environment Variables
```bash
DATABASE_URL=postgresql://postgres:DPVils25!@localhost:5432/canvas_course_generator
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG
```

## Technical Architecture

### Frontend
- React with TypeScript
- Vite build system
- shadcn/ui components
- TanStack Query for state management

### Backend
- Node.js with Express
- PostgreSQL database
- Drizzle ORM
- Canvas API integration

### Deployment
- AWS EC2 Ubuntu 22.04
- Nginx reverse proxy
- Systemd process management
- SSL-ready configuration

## Next Steps
1. Complete systemd service deployment
2. Test application functionality
3. Configure SSL certificates (optional)
4. Setup monitoring and logging