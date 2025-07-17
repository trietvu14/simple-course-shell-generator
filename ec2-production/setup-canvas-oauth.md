# Canvas OAuth Setup for Production

## Overview
This guide sets up Canvas OAuth refresh token functionality to automatically renew access tokens when they expire after 1 hour.

## Required Environment Variables

Add these to your `.env` file:

```bash
# Canvas OAuth Configuration
CANVAS_CLIENT_ID=your_canvas_client_id
CANVAS_CLIENT_SECRET=your_canvas_client_secret
CANVAS_REDIRECT_URI=https://shell.dpvils.org/api/canvas/oauth/callback
CANVAS_API_URL=https://your-canvas-domain.com/api/v1

# Session configuration for OAuth state management
SESSION_SECRET=your_secure_session_secret
```

## Canvas Developer Key Setup

1. **Access Canvas Admin Panel**:
   - Log in to your Canvas instance as an administrator
   - Navigate to Admin → Developer Keys

2. **Create New Developer Key**:
   - Click "Developer Key" → "API Key"
   - Fill in the details:
     - **Key Name**: Canvas Course Shell Generator
     - **Owner Email**: admin@digitalpromise.org
     - **Redirect URI**: https://shell.dpvils.org/api/canvas/oauth/callback
     - **Scopes**: Select these permissions:
       - `url:GET|/api/v1/accounts` - Read account information
       - `url:GET|/api/v1/accounts/*/courses` - Read courses
       - `url:POST|/api/v1/accounts/*/courses` - Create courses

3. **Save and Enable**:
   - Click "Save Key"
   - Enable the key by clicking the "ON" toggle
   - Copy the **Client ID** and **Client Secret**

## OAuth Flow

### 1. Authorization Request
Users click "Connect Canvas" which redirects to:
```
GET /api/canvas/oauth/authorize
```

### 2. Canvas Authorization
User is redirected to Canvas to approve permissions:
```
https://your-canvas-domain.com/login/oauth2/auth?client_id=...&response_type=code&redirect_uri=...
```

### 3. Authorization Callback
Canvas redirects back with authorization code:
```
GET /api/canvas/oauth/callback?code=...&state=...
```

### 4. Token Exchange
Server exchanges code for access and refresh tokens:
```
POST https://your-canvas-domain.com/login/oauth2/token
```

### 5. Token Storage
Access token, refresh token, and expiry are stored in database.

## Automatic Token Refresh

The system automatically refreshes tokens when:
- Current token expires within 5 minutes
- API request returns 401 Unauthorized

Refresh process:
1. Use stored refresh token to get new access token
2. Update database with new token and expiry
3. Retry original API request

## API Endpoints

### OAuth Management
- `GET /api/canvas/oauth/authorize` - Start OAuth flow
- `GET /api/canvas/oauth/callback` - Handle OAuth callback
- `DELETE /api/canvas/oauth/revoke` - Revoke tokens
- `GET /api/canvas/oauth/status` - Check token status

### Canvas API (with auto-refresh)
- `GET /api/accounts` - List Canvas accounts
- `POST /api/course-shells` - Create course shells
- `GET /api/batches/:id` - Get batch status

## Database Schema

The `canvas_tokens` table stores:
- `user_id` - Associated user
- `access_token` - Current access token
- `refresh_token` - Token for refreshing access
- `expires_at` - When access token expires
- `scope` - Granted permissions
- `token_type` - Usually "Bearer"

## Error Handling

### Token Refresh Failures
- User sees "Canvas authorization expired" message
- Redirected to re-authorize Canvas access
- Previous tokens are revoked

### API Request Failures
- 401 Unauthorized triggers automatic token refresh
- Other errors are logged and returned to user
- Rate limiting is handled with exponential backoff

## Testing

1. **Manual Testing**:
   ```bash
   curl -X GET "https://shell.dpvils.org/api/canvas/oauth/status" \
     -H "Authorization: Bearer YOUR_SESSION_TOKEN"
   ```

2. **Token Refresh Testing**:
   - Wait for token to expire (1 hour)
   - Make API request to `/api/accounts`
   - Check logs for automatic refresh

## Security Considerations

1. **Client Secret Protection**:
   - Never expose client secret in frontend code
   - Store securely in environment variables
   - Rotate regularly

2. **Token Storage**:
   - Access tokens stored encrypted in database
   - Refresh tokens have long lifetime - protect carefully
   - Implement token revocation on user logout

3. **State Parameter**:
   - Prevents CSRF attacks during OAuth flow
   - Validated on callback to ensure request authenticity

## Troubleshooting

### Common Issues

1. **Invalid Client ID/Secret**:
   - Verify Canvas developer key is enabled
   - Check environment variables are correct

2. **Redirect URI Mismatch**:
   - Ensure Canvas developer key has exact redirect URI
   - Must match production domain

3. **Scope Permissions**:
   - Verify all required scopes are enabled
   - Test with minimal scopes first

4. **Token Refresh Fails**:
   - Check refresh token hasn't expired
   - Verify Canvas developer key is still active

### Debug Commands

```bash
# Check token status
curl -X GET "https://shell.dpvils.org/api/canvas/oauth/status"

# Test Canvas API
curl -X GET "https://shell.dpvils.org/api/accounts"

# Check logs
sudo journalctl -u canvas-course-generator.service -f
```

## Implementation Status

✅ **Complete Features**:
- OAuth authorization flow
- Token storage and management
- Automatic token refresh
- Error handling and fallbacks
- Database schema and migrations

🔄 **Next Steps**:
1. Configure Canvas developer key
2. Update production environment variables
3. Test OAuth flow end-to-end
4. Monitor token refresh in production

This implementation provides robust Canvas integration with automatic token management, ensuring uninterrupted access to Canvas APIs.