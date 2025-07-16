import { OktaAuth } from '@okta/okta-auth-js';

const oktaConfig = {
  issuer: 'https://digitalpromise.okta.com/oauth2/default',
  clientId: '0oapma7d718cb4oYu5d7',
  redirectUri: `${window.location.origin}/callback`,
  scopes: ['openid', 'profile', 'email'],
  pkce: true,
  restoreOriginalUri: async (oktaAuth: OktaAuth, originalUri: string) => {
    window.location.replace(originalUri || '/dashboard');
  },
};

export const oktaAuth = new OktaAuth(oktaConfig);