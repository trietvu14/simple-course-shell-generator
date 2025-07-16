const express = require('express');
const app = express();

// Test Okta configuration
const OKTA_CLIENT_ID = process.env.OKTA_CLIENT_ID || '0oapma7d718cb4oYu5d7';
const OKTA_ISSUER = process.env.OKTA_ISSUER || 'https://digitalpromise.okta.com/oauth2/default';
const OKTA_REDIRECT_URI = process.env.OKTA_REDIRECT_URI || 'https://shell.dpvils.org/callback';

console.log('Current Okta Configuration:');
console.log('- Client ID:', OKTA_CLIENT_ID);
console.log('- Issuer:', OKTA_ISSUER);
console.log('- Redirect URI:', OKTA_REDIRECT_URI);

// Test the authorization URL
const authUrl = `${OKTA_ISSUER}/v1/authorize?client_id=${OKTA_CLIENT_ID}&response_type=code&scope=openid profile email&redirect_uri=${encodeURIComponent(OKTA_REDIRECT_URI)}&state=test`;

console.log('\nAuthorization URL:');
console.log(authUrl);

console.log('\nTo fix the redirect URI error:');
console.log('1. Go to: https://digitalpromise-admin.okta.com/admin/app/oidc_client/instance/0oapma7d718cb4oYu5d7#tab-general');
console.log('2. Add this redirect URI:', OKTA_REDIRECT_URI);
console.log('3. Save the changes');