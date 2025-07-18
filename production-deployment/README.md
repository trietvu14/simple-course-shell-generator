# Canvas Course Shell Generator

A full-stack web application for creating Canvas course shells through an automated system. This application provides a user-friendly interface for educational administrators to bulk-create course shells in Canvas LMS by selecting organizational accounts and defining course parameters.

## Features

- **Okta Authentication**: Secure Single Sign-On with Digital Promise Okta
- **Canvas Integration**: Direct integration with Canvas LMS API
- **Hierarchical Account Management**: Browse and select from all Canvas account levels
- **Bulk Course Creation**: Create multiple course shells simultaneously
- **Real-time Progress Tracking**: Monitor course creation progress with live updates
- **Production Ready**: Complete AWS EC2 deployment configuration

## Technology Stack

### Frontend
- **React** with TypeScript
- **Vite** for fast development and optimized builds
- **Radix UI** components with shadcn/ui styling
- **Tailwind CSS** for responsive design
- **TanStack Query** for server state management
- **Wouter** for client-side routing

### Backend
- **Node.js** with Express.js
- **TypeScript** with ES modules
- **PostgreSQL** with Drizzle ORM
- **Canvas LMS API** integration
- **Okta Authentication** integration

### Infrastructure
- **AWS EC2** production deployment
- **Nginx** reverse proxy with SSL
- **PM2** process management
- **PostgreSQL** database with automated backups

## Quick Start

### Development

1. Clone the repository:
```bash
git clone <repository-url>
cd canvas-course-generator
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Set up the database:
```bash
npm run db:push
```

5. Start the development server:
```bash
npm run dev
```

The application will be available at `http://localhost:5000`

### Production Deployment

For production deployment on AWS EC2, follow the comprehensive guides in the `deployment/` directory:

- `deployment/quick-start.md` - Step-by-step deployment guide
- `deployment/aws-ec2-setup.md` - Complete technical setup documentation
- `deployment/deployment-checklist.md` - Deployment verification checklist

## Environment Variables

### Required Variables
- `CANVAS_API_URL` - Your Canvas instance URL
- `CANVAS_API_TOKEN` - Canvas API access token
- `OKTA_CLIENT_ID` - Okta application client ID
- `OKTA_CLIENT_SECRET` - Okta application client secret
- `OKTA_ISSUER` - Okta domain URL
- `DATABASE_URL` - PostgreSQL connection string

### Optional Variables
- `PORT` - Application port (default: 5000)
- `NODE_ENV` - Environment (development/production)
- `SESSION_SECRET` - Session security key
- `LOG_LEVEL` - Logging level

## API Endpoints

- `GET /health` - Health check endpoint
- `GET /api/canvas/accounts` - Fetch Canvas account hierarchy
- `POST /api/course-shells` - Create course shells
- `GET /api/batch-status/:batchId` - Get batch creation status
- `GET /api/recent-activity` - Get recent creation batches

## Database Schema

- **Users**: Okta-integrated user management
- **Canvas Accounts**: Cached account hierarchy
- **Course Shells**: Course creation requests and status
- **Creation Batches**: Grouped course creation operations

## Security

- Okta Single Sign-On authentication
- HTTPS with Let's Encrypt certificates
- Security headers and CORS configuration
- Input validation and sanitization
- Session management with secure cookies

## Monitoring

- Health check endpoint for uptime monitoring
- PM2 process monitoring
- Database connection health checks
- Application performance metrics
- Automated backup systems

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions, please contact the Digital Promise development team.

---

## Architecture Overview

The application follows a modern full-stack architecture:

- **Frontend**: React SPA with TypeScript and modern UI components
- **Backend**: Node.js/Express API server with TypeScript
- **Database**: PostgreSQL with Drizzle ORM for type-safe queries
- **Authentication**: Okta SSO integration
- **Deployment**: AWS EC2 with Nginx, PM2, and automated deployment scripts

The system is designed to handle bulk operations efficiently while providing real-time feedback to users through progress tracking and status updates.