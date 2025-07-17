#!/bin/bash

echo "=== Canvas Course Shell Generator - Production Okta Deployment ==="
echo "Deploying application with Okta authentication to production..."

TARGET_DIR="/home/ubuntu/canvas-course-generator"
BACKUP_DIR="/home/ubuntu/backup-$(date +%Y%m%d-%H%M%S)"

# Stop the service
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

# Create backup
echo "2. Creating backup..."
sudo cp -r "$TARGET_DIR" "$BACKUP_DIR"

# Create deployment directory
echo "3. Creating deployment directories..."
mkdir -p production-deployment
mkdir -p production-deployment/client/src/lib
mkdir -p production-deployment/client/src/pages
mkdir -p production-deployment/client/src/components
mkdir -p production-deployment/server
mkdir -p production-deployment/shared

# Copy core files
echo "4. Copying application files..."
cp -r client/* production-deployment/client/
cp -r server/* production-deployment/server/
cp -r shared/* production-deployment/shared/
cp -r public production-deployment/
cp package*.json production-deployment/
cp tsconfig.json production-deployment/
cp vite.config.ts production-deployment/
cp tailwind.config.ts production-deployment/
cp postcss.config.js production-deployment/
cp components.json production-deployment/
cp drizzle.config.ts production-deployment/

# Copy environment configuration
echo "5. Copying environment configuration..."
cp .env production-deployment/.env

# Create systemd service file
echo "6. Creating systemd service..."
cat > production-deployment/canvas-course-generator.service << 'EOF'
[Unit]
Description=Canvas Course Shell Generator - React
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/canvas-course-generator
Environment=NODE_ENV=production
EnvironmentFile=/home/ubuntu/canvas-course-generator/.env
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create deployment script
echo "7. Creating deployment script..."
cat > production-deployment/deploy-to-production.sh << 'EOF'
#!/bin/bash

echo "=== Deploying to Production Server ==="

# Stop service
sudo systemctl stop canvas-course-generator.service

# Copy files
sudo cp -r . /home/ubuntu/canvas-course-generator/
sudo chown -R ubuntu:ubuntu /home/ubuntu/canvas-course-generator

# Install dependencies
cd /home/ubuntu/canvas-course-generator
npm install

# Install systemd service
sudo cp canvas-course-generator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable canvas-course-generator.service

# Start service
sudo systemctl start canvas-course-generator.service

# Check status
sudo systemctl status canvas-course-generator.service

echo "Deployment complete!"
echo "Check logs with: sudo journalctl -u canvas-course-generator.service -f"
EOF

chmod +x production-deployment/deploy-to-production.sh

# Create README for production
echo "8. Creating production README..."
cat > production-deployment/PRODUCTION-README.md << 'EOF'
# Canvas Course Shell Generator - Production Deployment

## Okta Authentication Configuration

This deployment includes Okta authentication configured for Digital Promise:

- **Okta Issuer**: https://digitalpromise.okta.com/oauth2/default
- **Client ID**: 0oapma7d718cb4oYu5d7
- **Redirect URI**: https://shell.dpvils.org/callback

## Environment Variables

The following environment variables are configured in `.env`:

```
CANVAS_API_URL=https://dppowerfullearning.instructure.com/api/v1
CANVAS_API_TOKEN=${CANVAS_API_TOKEN}
DATABASE_URL=${DATABASE_URL}
CANVAS_CLIENT_ID=280980000000000004
CANVAS_CLIENT_SECRET=Gy3PtTYcXTFWZ7kn93DkBreWzfztYyxyUXer8RCcfWr4JQcLUW9K2BYcuu7LQVYa
CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback
SESSION_SECRET=c5e3c9d4-d06e-4fae-89e8-0fa6805c0668
VITE_OKTA_ISSUER=https://digitalpromise.okta.com/oauth2/default
VITE_OKTA_CLIENT_ID=0oapma7d718cb4oYu5d7
VITE_SIMPLE_AUTH=false
```

## Deployment Instructions

1. Upload this directory to the production server
2. Run the deployment script: `./deploy-to-production.sh`
3. Monitor the service: `sudo journalctl -u canvas-course-generator.service -f`

## Testing Okta Authentication

1. Access https://shell.dpvils.org
2. You should be redirected to Digital Promise Okta login
3. After authentication, you'll be redirected back to the application
4. The application will automatically create/update your user record in the database

## Troubleshooting

- Check service status: `sudo systemctl status canvas-course-generator.service`
- View logs: `sudo journalctl -u canvas-course-generator.service -f`
- Restart service: `sudo systemctl restart canvas-course-generator.service`
EOF

echo ""
echo "=== Production Deployment Package Created ==="
echo "✓ Application files copied to production-deployment/"
echo "✓ Okta authentication configured"
echo "✓ Environment variables set"
echo "✓ Systemd service file created"
echo "✓ Deployment script ready"
echo ""
echo "To deploy to production:"
echo "1. Upload the production-deployment/ directory to the server"
echo "2. Run: ./deploy-to-production.sh"
echo "3. Test at: https://shell.dpvils.org"
echo ""
echo "The application will use Okta authentication with Digital Promise SSO."