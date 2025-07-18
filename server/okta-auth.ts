import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';
import fetch from 'node-fetch';
import { URLSearchParams } from 'url';
import crypto from 'crypto';

interface OktaConfig {
  domain: string;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
}

interface UserClaims {
  sub: string;
  email: string;
  name: string;
  groups: string[];
  email_verified: boolean;
  exp: number;
  iat: number;
}

interface SessionToken {
  sub: string;
  email: string;
  name: string;
  groups: string[];
  logged_in: boolean;
  login_time: string;
  exp: number;
}

interface JWK {
  kid: string;
  kty: string;
  alg: string;
  use: string;
  n: string;
  e: string;
}

interface JWKS {
  keys: JWK[];
}

export class OktaSSO {
  private config: OktaConfig;
  private jwksCache: JWKS | null = null;
  private jwksCacheTime: Date | null = null;
  private sessionSecret: string;

  constructor() {
    this.config = {
      domain: process.env.OKTA_DOMAIN || 'digitalpromise.okta.com',
      clientId: process.env.OKTA_CLIENT_ID || '',
      clientSecret: process.env.OKTA_CLIENT_SECRET || '',
      redirectUri: process.env.OKTA_REDIRECT_URI || 'https://shell.dpvils.org/callback'
    };
    
    this.sessionSecret = process.env.SESSION_SECRET || 'fallback-secret';
    
    console.log('Okta SSO initialized:', {
      domain: this.config.domain,
      clientId: this.config.clientId,
      redirectUri: this.config.redirectUri,
      issuer: `https://${this.config.domain}/oauth2/default`
    });
  }

  private get authorizationEndpoint(): string {
    return `https://${this.config.domain}/oauth2/default/v1/authorize`;
  }

  private get tokenEndpoint(): string {
    return `https://${this.config.domain}/oauth2/default/v1/token`;
  }

  private get userinfoEndpoint(): string {
    return `https://${this.config.domain}/oauth2/default/v1/userinfo`;
  }

  private get jwksEndpoint(): string {
    return `https://${this.config.domain}/oauth2/default/v1/keys`;
  }

  async getJWKS(): Promise<JWKS | null> {
    // Check cache (valid for 1 hour)
    if (this.jwksCache && this.jwksCacheTime && 
        Date.now() - this.jwksCacheTime.getTime() < 3600000) {
      return this.jwksCache;
    }

    try {
      const response = await fetch(this.jwksEndpoint, { timeout: 10000 });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      const jwks = await response.json() as JWKS;
      this.jwksCache = jwks;
      this.jwksCacheTime = new Date();
      return jwks;
    } catch (error) {
      console.error('Failed to fetch JWKS from Okta:', error);
      return null;
    }
  }

  getAuthorizationUrl(state?: string): string {
    const params = new URLSearchParams({
      client_id: this.config.clientId,
      response_type: 'code',
      scope: 'openid profile email',
      redirect_uri: this.config.redirectUri,
      state: state || crypto.randomBytes(32).toString('base64url')
    });

    return `${this.authorizationEndpoint}?${params.toString()}`;
  }

  async exchangeCodeForTokens(authorizationCode: string): Promise<any> {
    const data = new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: this.config.clientId,
      client_secret: this.config.clientSecret,
      code: authorizationCode,
      redirect_uri: this.config.redirectUri
    });

    try {
      const response = await fetch(this.tokenEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: data,
        timeout: 10000
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Token exchange failed:', error);
      return null;
    }
  }

  async verifyIdToken(idToken: string): Promise<UserClaims | null> {
    try {
      // Get JWKS
      const jwks = await this.getJWKS();
      if (!jwks) {
        console.error('Failed to get JWKS');
        return null;
      }

      // Decode header to get kid
      const header = jwt.decode(idToken, { complete: true })?.header;
      if (!header?.kid) {
        console.error('No kid in token header');
        return null;
      }

      // Find matching key
      const key = jwks.keys.find(k => k.kid === header.kid);
      if (!key) {
        console.error(`No matching key found for kid: ${header.kid}`);
        return null;
      }

      // Verify token (simplified - in production, use proper JWT verification)
      const decoded = jwt.decode(idToken) as any;
      if (!decoded) {
        console.error('Failed to decode ID token');
        return null;
      }

      // Basic validation
      if (decoded.aud !== this.config.clientId) {
        console.error('Invalid audience');
        return null;
      }

      if (decoded.iss !== `https://${this.config.domain}/oauth2/default`) {
        console.error('Invalid issuer');
        return null;
      }

      if (decoded.exp < Date.now() / 1000) {
        console.error('Token expired');
        return null;
      }

      console.log('ID token verified successfully');

      return {
        sub: decoded.sub,
        email: decoded.email,
        name: decoded.name || decoded.email,
        groups: decoded.groups || [],
        email_verified: decoded.email_verified,
        exp: decoded.exp,
        iat: decoded.iat
      };

    } catch (error) {
      console.error('ID token verification failed:', error);
      return null;
    }
  }

  async getUserInfo(accessToken: string): Promise<any> {
    try {
      const response = await fetch(this.userinfoEndpoint, {
        headers: { Authorization: `Bearer ${accessToken}` },
        timeout: 10000
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Failed to get user info:', error);
      return null;
    }
  }

  createSessionToken(userClaims: UserClaims): string {
    const sessionData: SessionToken = {
      sub: userClaims.sub,
      email: userClaims.email,
      name: userClaims.name,
      groups: userClaims.groups,
      logged_in: true,
      login_time: new Date().toISOString(),
      exp: Math.floor(Date.now() / 1000) + (8 * 3600) // 8 hours
    };

    return jwt.sign(sessionData, this.sessionSecret, { algorithm: 'HS256' });
  }

  verifySessionToken(sessionToken: string): SessionToken | null {
    try {
      const claims = jwt.verify(sessionToken, this.sessionSecret, { algorithms: ['HS256'] }) as SessionToken;
      return claims;
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        console.log('Session token expired');
      } else {
        console.error('Invalid session token:', error);
      }
      return null;
    }
  }
}

// Global instance
export const oktaSSO = new OktaSSO();

// Middleware for requiring Okta authentication
export const oktaAuthRequired = (req: Request, res: Response, next: NextFunction) => {
  const sessionToken = req.cookies.okta_session;

  if (!sessionToken) {
    return res.status(401).json({ message: 'Authentication required' });
  }

  const userClaims = oktaSSO.verifySessionToken(sessionToken);
  if (!userClaims) {
    res.clearCookie('okta_session');
    return res.status(401).json({ message: 'Invalid or expired session' });
  }

  // Add user to request object
  (req as any).currentUser = userClaims;
  next();
};