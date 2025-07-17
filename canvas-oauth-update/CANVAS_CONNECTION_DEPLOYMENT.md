# Canvas Connection Button - Deployment Guide

## Overview
This guide explains how to deploy the new "Connect Canvas" button and Canvas connection status interface that was added to solve the 1-hour token expiry issue.

## New Components Added

### 1. Canvas Connection Component
**File**: `client/src/components/canvas-connection.tsx`
- Displays Canvas connection status (Connected/Not Connected/Expired)
- Shows token expiry countdown
- Provides "Connect Canvas" button for OAuth authorization
- Handles token revocation with "Disconnect Canvas" button

### 2. UI Components
**Files**: 
- `client/src/components/ui/badge.tsx` - Status badges
- `client/src/components/ui/card.tsx` - Card layout for connection status

### 3. Updated Dashboard
**File**: `client/src/pages/dashboard.tsx`
- Integrates Canvas connection component above account selection
- Updated layout to accommodate new connection interface

## Visual Interface

The Canvas connection interface appears as a card at the top of the dashboard:

```
┌─────────────────────────────────────────────────┐
│ 🔗 Canvas Connection            [Connected]     │
│ Connect your Canvas account to access course... │
│                                                 │
│ ✅ Connected • Expires in 45m                   │
│ Permissions: account_read course_write          │
│                                                 │
│ [🔗 Connect Canvas]  [⚠️ Disconnect Canvas]     │
└─────────────────────────────────────────────────┘
```

## Backend API Integration

The component connects to these OAuth endpoints:
- `GET /api/canvas/oauth/status` - Check token status
- `GET /api/canvas/oauth/authorize` - Start OAuth flow
- `DELETE /api/canvas/oauth/revoke` - Revoke access

## Deployment Steps

### Step 1: Copy Updated Files
```bash
# Copy new components to your production server
scp canvas-oauth-update/client/src/components/canvas-connection.tsx \
    ubuntu@your-server:/path/to/app/client/src/components/

scp canvas-oauth-update/client/src/components/ui/badge.tsx \
    ubuntu@your-server:/path/to/app/client/src/components/ui/

scp canvas-oauth-update/client/src/components/ui/card.tsx \
    ubuntu@your-server:/path/to/app/client/src/components/ui/

scp canvas-oauth-update/client/src/pages/dashboard.tsx \
    ubuntu@your-server:/path/to/app/client/src/pages/
```

### Step 2: Update Dependencies
The Canvas connection component requires these packages (already included in package.json):
- `@radix-ui/react-slot` - For card components
- `class-variance-authority` - For badge variants
- `lucide-react` - For icons

### Step 3: Rebuild Application
```bash
cd /path/to/app
npm run build
sudo systemctl restart your-app-service
```

### Step 4: Configure Canvas Developer Key
Follow the setup guide in `setup-canvas-oauth.md` to configure Canvas OAuth:
1. Create Canvas developer key
2. Set redirect URI to `https://shell.dpvils.org/api/canvas/oauth/callback`
3. Add environment variables:
   - `CANVAS_CLIENT_ID=your_client_id`
   - `CANVAS_CLIENT_SECRET=your_client_secret`

## User Experience Flow

### Before OAuth Setup (Current State)
1. User sees "Canvas not connected" status
2. Click "Connect Canvas" → redirects to Canvas OAuth
3. User authorizes → redirected back with tokens
4. Status shows "Connected • Expires in 55m"

### After OAuth Setup (Production)
1. System automatically refreshes tokens before expiry
2. User never needs to manually generate API tokens
3. Canvas accounts always load without interruption
4. Status always shows current connection state

## Features

### Real-time Status Updates
- Checks token status every minute
- Shows countdown to token expiry
- Automatically detects expired tokens

### Error Handling
- Graceful handling of OAuth failures
- Clear error messages to users
- Automatic fallback to static tokens if OAuth not configured

### Security
- Secure token storage in PostgreSQL
- State validation for OAuth flow
- Token rotation on refresh

## Testing

After deployment, test the Canvas connection:

1. **Login** to the application
2. **Navigate** to dashboard
3. **Check** Canvas connection status card appears
4. **Click** "Connect Canvas" (will redirect to Canvas OAuth)
5. **Authorize** the application in Canvas
6. **Verify** status shows "Connected" with expiry time

## Production Benefits

Once deployed, users will:
- ✅ Never need to manually generate Canvas API tokens
- ✅ Have seamless Canvas account loading without interruption
- ✅ See clear status of their Canvas connection
- ✅ Have automatic token refresh preventing expiry issues

The Canvas connection interface provides a professional, user-friendly way to manage Canvas OAuth authentication while solving the 1-hour token expiry problem permanently.