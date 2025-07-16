# GitHub Repository Setup Guide

## Step 1: Create GitHub Repository

1. Go to [GitHub.com](https://github.com) and sign in
2. Click the "+" icon in the top right corner
3. Select "New repository"
4. Fill in the details:
   - **Repository name**: `canvas-course-shell-generator`
   - **Description**: `Canvas Course Shell Generator - Automated course creation tool with Okta authentication`
   - **Visibility**: Choose Public or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click "Create repository"

## Step 2: Commit and Push to GitHub

Open your terminal and run these commands:

```bash
# Navigate to your project directory
cd /path/to/your/canvas-course-shell-generator

# Remove any git lock files
rm -f .git/index.lock

# Check current status
git status

# Add all files to staging
git add .

# Commit with descriptive message
git commit -m "feat: Complete Canvas Course Shell Generator with production deployment

- Implemented Okta SSO authentication with Digital Promise
- Added Canvas API integration for course shell creation
- Created hierarchical account selection interface
- Added real-time progress tracking for bulk operations
- Included comprehensive AWS EC2 deployment package
- Added health checks, monitoring, and automated backups
- Created production-ready documentation and deployment scripts"

# Add your GitHub repository as remote (replace YOUR_USERNAME with your actual GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/canvas-course-shell-generator.git

# Push to GitHub
git push -u origin main
```

## Step 3: Verify Upload

1. Go to your GitHub repository page
2. Verify all files are present:
   - `README.md` - Project documentation
   - `LICENSE` - MIT license
   - `deployment/` folder with all deployment files
   - Application source code in `client/`, `server/`, `shared/`
   - Configuration files

## Step 4: Set Up Repository Settings

### Enable GitHub Pages (Optional)
1. Go to repository Settings > Pages
2. Select source: Deploy from a branch
3. Choose `main` branch and `/docs` folder if you want to host documentation

### Add Repository Topics
1. Go to repository Settings > General
2. Add topics: `canvas`, `lms`, `course-management`, `react`, `nodejs`, `okta`, `aws`, `education`

### Configure Branch Protection (Recommended)
1. Go to repository Settings > Branches
2. Add branch protection rule for `main`
3. Enable:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

## Step 5: Set Up Development Workflow

### Clone Repository for Development
```bash
git clone https://github.com/YOUR_USERNAME/canvas-course-shell-generator.git
cd canvas-course-shell-generator
npm install
```

### Create Development Branch
```bash
git checkout -b development
git push -u origin development
```

### Set Up Environment Variables
```bash
cp deployment/.env.production.example .env
# Edit .env with your actual values
```

## Repository Structure

Your repository now contains:

```
canvas-course-shell-generator/
├── README.md                    # Project documentation
├── LICENSE                      # MIT license
├── package.json                 # Dependencies and scripts
├── .gitignore                   # Git exclusion rules
├── replit.md                    # Project architecture documentation
├── client/                      # React frontend
│   ├── src/
│   │   ├── components/         # UI components
│   │   ├── lib/               # Utilities and configurations
│   │   └── pages/             # Application pages
│   └── index.html
├── server/                      # Node.js backend
│   ├── routes.ts              # API routes
│   ├── storage.ts             # Database operations
│   ├── health.ts              # Health check endpoint
│   └── index.ts               # Server entry point
├── shared/                      # Shared types and schemas
│   └── schema.ts              # Database schema
├── deployment/                  # Production deployment package
│   ├── aws-ec2-setup.md        # Complete setup guide
│   ├── quick-start.md          # Quick deployment guide
│   ├── deployment-checklist.md # Verification checklist
│   ├── ecosystem.config.js     # PM2 configuration
│   ├── nginx-config            # Nginx configuration
│   ├── deploy.sh              # Deployment automation
│   ├── backup-db.sh           # Database backup script
│   └── .env.production.example # Environment template
└── attached_assets/            # Canvas logo assets
```

## Troubleshooting

### Git Lock File Error
```bash
rm -f .git/index.lock
```

### Permission Denied
```bash
sudo chown -R $USER:$USER .git
chmod -R 755 .git
```

### Remote Already Exists
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/canvas-course-shell-generator.git
```

### Authentication Issues
- Use Personal Access Token instead of password
- Configure SSH keys for easier authentication
- Enable two-factor authentication for security

## Next Steps

1. **Set up CI/CD** - Consider GitHub Actions for automated testing and deployment
2. **Configure Dependabot** - Automatic dependency updates
3. **Add Issue Templates** - Standardize bug reports and feature requests
4. **Create Documentation Wiki** - Detailed technical documentation
5. **Set up Security Scanning** - CodeQL and dependency vulnerability scanning

Your Canvas Course Shell Generator is now ready for collaborative development and production deployment!