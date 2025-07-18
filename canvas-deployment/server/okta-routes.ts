import { Router, Request, Response } from 'express';
import { oktaSSO } from './okta-auth';

const router = Router();

// Okta login endpoint
router.get('/login', (req: Request, res: Response) => {
  const state = req.query.state as string;
  const authUrl = oktaSSO.getAuthorizationUrl(state);
  res.redirect(authUrl);
});

// Okta callback endpoint (matches Okta app configuration)
router.get('/callback', async (req: Request, res: Response) => {
  const { code, state, error } = req.query;

  if (error) {
    console.error('Okta callback error:', error);
    return res.redirect('/?error=auth_failed');
  }

  if (!code) {
    console.error('No authorization code received');
    return res.redirect('/?error=no_code');
  }

  try {
    // Exchange code for tokens
    const tokens = await oktaSSO.exchangeCodeForTokens(code as string);
    if (!tokens) {
      console.error('Failed to exchange code for tokens');
      return res.redirect('/?error=token_exchange_failed');
    }

    // Verify ID token and get user claims
    const userClaims = await oktaSSO.verifyIdToken(tokens.id_token);
    if (!userClaims) {
      console.error('Failed to verify ID token');
      return res.redirect('/?error=token_verification_failed');
    }

    // Create session token
    const sessionToken = oktaSSO.createSessionToken(userClaims);

    // Set secure cookie
    res.cookie('okta_session', sessionToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 8 * 60 * 60 * 1000 // 8 hours
    });

    console.log('User authenticated successfully:', userClaims.email);
    res.redirect('/');

  } catch (error) {
    console.error('Okta callback processing error:', error);
    res.redirect('/?error=auth_processing_failed');
  }
});

// Okta logout endpoint
router.post('/logout', (req: Request, res: Response) => {
  res.clearCookie('okta_session');
  res.json({ message: 'Logged out successfully' });
});

// Get current user endpoint
router.get('/user', (req: Request, res: Response) => {
  const sessionToken = req.cookies.okta_session;

  if (!sessionToken) {
    return res.status(401).json({ message: 'Not authenticated' });
  }

  const userClaims = oktaSSO.verifySessionToken(sessionToken);
  if (!userClaims) {
    res.clearCookie('okta_session');
    return res.status(401).json({ message: 'Invalid or expired session' });
  }

  res.json({
    id: userClaims.sub,
    email: userClaims.email,
    name: userClaims.name,
    groups: userClaims.groups,
    loginTime: userClaims.login_time
  });
});

export default router;