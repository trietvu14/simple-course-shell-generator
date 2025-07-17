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
