# Canvas API Token Expired - Action Required

## 🚨 Issue Detected
The Canvas API token has expired, returning 401 "Invalid access token" error.

## 📋 Current Status
- ✅ Canvas OAuth infrastructure fully implemented
- ✅ Canvas developer key configured correctly
- ✅ Redirect URI properly set: `https://shell.dpvils.org/api/canvas/oauth/callback`
- ❌ Canvas API token expired: `28098~rvMvz2ZRQyCXPrQPHeREnyvZhcuM22yKF8Bh3vKYJUkmQhTkwfKTRMm7UTWDe7mG`

## 🔧 Required Actions

### 1. Generate New Canvas API Token
1. Go to: https://dppowerfullearning.instructure.com/profile/settings
2. Scroll to "Approved Integrations" section
3. Click "+ New Access Token"
4. Purpose: "Canvas Course Shell Generator"
5. Expiry: Set to 1 year from now
6. Copy the generated token

### 2. Update Production Environment
```bash
# Update Canvas API token in production
ssh ubuntu@shell.dpvils.org
sudo nano /home/ubuntu/canvas-course-generator/.env
# Replace CANVAS_API_TOKEN with new token
sudo systemctl restart canvas-course-generator.service
```

### 3. Update Replit Environment
```bash
# Update Canvas API token in Replit
nano .env
# Replace CANVAS_API_TOKEN with new token
```

## 🎯 Expected Results After Token Update
- Canvas API calls will work with new static token
- Canvas OAuth system will have working fallback
- Account loading will function correctly
- Course shell creation will work end-to-end

## 🏆 Canvas OAuth Flow Ready
Once the token is updated, the Canvas OAuth system is ready for testing:
1. Visit: https://shell.dpvils.org
2. Click: "Connect Canvas" button
3. Complete Canvas authorization
4. OAuth tokens will be stored in database
5. System will use OAuth tokens instead of static token

The Canvas OAuth infrastructure is complete and ready for use once the API token is updated.