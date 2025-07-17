import { storage } from "./storage";
import { type User, type CanvasToken, type InsertCanvasToken } from "@shared/schema";

interface CanvasOAuthConfig {
  clientId: string;
  clientSecret: string;
  canvasUrl: string;
  redirectUri: string;
}

interface CanvasTokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  scope: string;
  token_type: string;
}

export class CanvasOAuthManager {
  private config: CanvasOAuthConfig;

  constructor(private storage: typeof storage) {
    this.config = {
      clientId: process.env.CANVAS_CLIENT_ID || process.env.CANVAS_CLIENT_KEY_ID || '',
      clientSecret: process.env.CANVAS_CLIENT_SECRET || '',
      canvasUrl: process.env.CANVAS_API_URL?.replace('/api/v1', '') || '',
      redirectUri: process.env.CANVAS_REDIRECT_URI || 'https://shell.dpvils.org/api/canvas/oauth/callback'
    };
    
    console.log('Canvas OAuth initialized with config:', {
      clientId: this.config.clientId,
      canvasUrl: this.config.canvasUrl,
      redirectUri: this.config.redirectUri
    });
  }

  /**
   * Generate Canvas OAuth authorization URL
   */
  getAuthorizationUrl(state?: string): string {
    const params = new URLSearchParams({
      client_id: this.config.clientId,
      response_type: 'code',
      redirect_uri: this.config.redirectUri,
      scope: 'url:GET|/api/v1/accounts url:GET|/api/v1/accounts/*/courses url:POST|/api/v1/accounts/*/courses',
      ...(state && { state })
    });

    return `${this.config.canvasUrl}/login/oauth2/auth?${params.toString()}`;
  }

  /**
   * Exchange authorization code for access token
   */
  async exchangeCodeForToken(code: string): Promise<CanvasTokenResponse> {
    const params = new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: this.config.clientId,
      client_secret: this.config.clientSecret,
      redirect_uri: this.config.redirectUri,
      code
    });

    const response = await fetch(`${this.config.canvasUrl}/login/oauth2/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: params.toString()
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Canvas OAuth token exchange failed: ${response.status} ${error}`);
    }

    return await response.json();
  }

  /**
   * Refresh an expired access token
   */
  async refreshToken(refreshToken: string): Promise<CanvasTokenResponse> {
    const params = new URLSearchParams({
      grant_type: 'refresh_token',
      client_id: this.config.clientId,
      client_secret: this.config.clientSecret,
      refresh_token: refreshToken
    });

    const tokenUrl = `${this.config.canvasUrl}/login/oauth2/token`;
    console.log('Refreshing Canvas token at:', tokenUrl);

    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: params.toString()
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Canvas token refresh failed: ${response.status} ${error}`);
    }

    return await response.json();
  }

  /**
   * Store or update Canvas tokens for a user
   */
  async storeTokens(userId: number, tokenResponse: CanvasTokenResponse): Promise<CanvasToken> {
    const expiresAt = new Date(Date.now() + (tokenResponse.expires_in * 1000));
    
    const tokenData: InsertCanvasToken = {
      userId,
      accessToken: tokenResponse.access_token,
      refreshToken: tokenResponse.refresh_token,
      expiresAt,
      scope: tokenResponse.scope,
      tokenType: tokenResponse.token_type || 'Bearer'
    };

    console.log('Storing Canvas tokens for user:', userId, 'expires at:', expiresAt);
    const storedToken = await this.storage.upsertCanvasToken(tokenData);
    console.log('Canvas tokens stored successfully:', storedToken.id);
    return storedToken;
  }

  /**
   * Get valid Canvas access token for a user (refresh if needed)
   */
  async getValidToken(userId: number): Promise<string> {
    const canvasToken = await this.storage.getCanvasToken(userId);
    
    if (!canvasToken) {
      throw new Error('No Canvas token found for user. Please authorize Canvas access.');
    }

    // Check if token is expired or will expire in the next 5 minutes
    const now = new Date();
    const expiryBuffer = new Date(canvasToken.expiresAt.getTime() - 5 * 60 * 1000); // 5 minutes before expiry
    
    if (now >= expiryBuffer) {
      console.log('Canvas token is expired or expiring soon, refreshing...');
      
      try {
        const refreshedToken = await this.refreshToken(canvasToken.refreshToken);
        const updatedToken = await this.storeTokens(userId, refreshedToken);
        console.log('Canvas token refreshed successfully');
        return updatedToken.accessToken;
      } catch (error) {
        console.error('Failed to refresh Canvas token:', error);
        // Remove invalid token
        await this.storage.deleteCanvasToken(userId);
        throw new Error('Canvas token refresh failed. Please re-authorize Canvas access.');
      }
    }

    return canvasToken.accessToken;
  }

  /**
   * Make authenticated Canvas API request with automatic token refresh
   */
  async makeCanvasApiRequest(userId: number, endpoint: string, options: RequestInit = {}): Promise<any> {
    const accessToken = await this.getValidToken(userId);
    
    const response = await fetch(`${this.config.canvasUrl}/api/v1${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Canvas API request failed: ${response.status} ${error}`);
    }

    return await response.json();
  }

  /**
   * Revoke Canvas tokens for a user
   */
  async revokeTokens(userId: number): Promise<void> {
    console.log('Revoking Canvas tokens for user:', userId);
    const canvasToken = await this.storage.getCanvasToken(userId);
    
    if (canvasToken) {
      try {
        // Revoke token with Canvas
        await fetch(`${this.config.canvasUrl}/login/oauth2/token`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${canvasToken.accessToken}`
          }
        });
      } catch (error) {
        console.error('Failed to revoke Canvas token:', error);
      }
      
      // Remove token from database
      await this.storage.deleteCanvasToken(userId);
    }
  }
}

export const canvasOAuth = new CanvasOAuthManager(storage);