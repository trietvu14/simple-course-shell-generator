# EC2 Production Deployment Files

## Required Files for Canvas OAuth Update

### Core Application Files
```
server/
├── canvas-oauth.ts          # NEW: Canvas OAuth manager
├── routes.ts               # UPDATED: Added OAuth endpoints
├── storage.ts              # UPDATED: Canvas token methods
├── db.ts                   # Database connection
├── index.ts                # Main server file
└── health.ts               # Health check endpoint

shared/
└── schema.ts               # UPDATED: Added canvas_tokens table

client/                     # Complete React frontend
├── src/
│   ├── components/
│   ├── pages/
│   ├── hooks/
│   └── lib/
└── index.html
```

### Configuration Files
```
package.json                # Dependencies
tsconfig.json              # TypeScript config
vite.config.ts             # Vite configuration
tailwind.config.ts         # Tailwind CSS config
postcss.config.js          # PostCSS config
drizzle.config.ts          # Database config
```

### Environment & Setup
```
.env                       # Environment variables (UPDATE REQUIRED)
setup-canvas-oauth.md      # Setup instructions
update-canvas-oauth.sh     # Deployment script
```

## What NOT to Upload

- `node_modules/` - Will be installed via npm
- `.git/` - Version control not needed in production
- `attached_assets/` - Development attachments
- `ec2-deployment/` - Old deployment folder
- Test files and development scripts

## Deployment Process

1. **Copy files** to EC2 server:
   ```bash
   scp -r server/ shared/ client/ package.json tsconfig.json vite.config.ts tailwind.config.ts postcss.config.js drizzle.config.ts ubuntu@your-server:/home/ubuntu/canvas-course-generator/
   ```

2. **Update environment variables** in `.env`:
   ```bash
   CANVAS_CLIENT_ID=your_canvas_client_id
   CANVAS_CLIENT_SECRET=your_canvas_client_secret
   CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback
   SESSION_SECRET=your_secure_session_secret
   ```

3. **Run deployment script**:
   ```bash
   ./update-canvas-oauth.sh
   ```

## File Sizes (Approximate)
- **server/**: ~50KB (6 files)
- **shared/**: ~5KB (1 file)  
- **client/**: ~200KB (React app)
- **config files**: ~10KB (6 files)
- **Total**: ~265KB

Much smaller than downloading the entire repository (~50MB with node_modules).