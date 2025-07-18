import type { Express, Request, Response, NextFunction } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { z } from "zod";
import { insertCreationBatchSchema, type User } from "@shared/schema";
import { nanoid } from "nanoid";
import { healthCheck } from "./health";
import { CanvasOAuthManager } from "./canvas-oauth";
import oktaRoutes from "./okta-routes";
import { oktaSSO } from "./okta-auth";

// Initialize Canvas OAuth manager with storage instance
const canvasOAuth = new CanvasOAuthManager(storage);

// Extend Express Request to include user property
interface AuthenticatedRequest extends Request {
  user: User;
}

// Canvas API configuration - loaded dynamically to ensure env vars are available
function getCanvasConfig() {
  const CANVAS_API_URL = process.env.CANVAS_API_URL || "https://your-canvas-domain.com/api/v1";
  const CANVAS_API_TOKEN = process.env.CANVAS_API_TOKEN || "";
  
  return { CANVAS_API_URL, CANVAS_API_TOKEN };
}

interface CanvasAccount {
  id: string;
  name: string;
  parent_account_id?: string;
  workflow_state: string;
  root_account_id?: string;
}

interface CanvasCourse {
  id: string;
  name: string;
  course_code: string;
  account_id: string;
  workflow_state: string;
  start_at?: string;
  end_at?: string;
}

async function makeCanvasApiRequest(userId: number, endpoint: string, options: RequestInit = {}) {
  const { CANVAS_API_URL } = getCanvasConfig();
  
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
  
  try {
    // Try to get OAuth token first (only if Canvas OAuth is properly configured)
    let authHeader = '';
    const hasOAuthConfig = (process.env.CANVAS_CLIENT_ID || process.env.CANVAS_CLIENT_KEY_ID) && process.env.CANVAS_CLIENT_SECRET;
    
    if (hasOAuthConfig) {
      try {
        const token = await canvasOAuth.getValidToken(userId);
        authHeader = `Bearer ${token}`;
        console.log('Using Canvas OAuth token');
      } catch (error) {
        console.log('OAuth token not available, falling back to static token');
        const { CANVAS_API_TOKEN } = getCanvasConfig();
        authHeader = `Bearer ${CANVAS_API_TOKEN}`;
      }
    } else {
      console.log('Using static Canvas API token');
      const { CANVAS_API_TOKEN } = getCanvasConfig();
      authHeader = `Bearer ${CANVAS_API_TOKEN}`;
    }
    
    const response = await fetch(`${CANVAS_API_URL}${endpoint}`, {
      ...options,
      signal: controller.signal,
      headers: {
        'Authorization': authHeader,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      // If 401 and we have OAuth configured, try to refresh token
      if (response.status === 401 && hasOAuthConfig) {
        try {
          const newToken = await canvasOAuth.getValidToken(userId);
          
          // Retry request with new token
          const retryResponse = await fetch(`${CANVAS_API_URL}${endpoint}`, {
            ...options,
            headers: {
              'Authorization': `Bearer ${newToken}`,
              'Content-Type': 'application/json',
              ...options.headers,
            },
          });
          
          if (retryResponse.ok) {
            return retryResponse.json();
          }
        } catch (refreshError) {
          console.error('Token refresh failed:', refreshError);
        }
      }
      
      throw new Error(`Canvas API error: ${response.status} ${response.statusText}`);
    }

    return response.json();
  } catch (error) {
    clearTimeout(timeoutId);
    if ((error as any).name === 'AbortError') {
      throw new Error('Canvas API request timed out');
    }
    throw error as Error;
  }
}

async function fetchSubAccountsRecursively(userId: number, accountId: string, depth: number = 0, maxDepth: number = 5): Promise<CanvasAccount[]> {
  if (depth > maxDepth) {
    console.log(`Max depth ${maxDepth} reached for account ${accountId}, skipping`);
    return [];
  }
  
  console.log(`Fetching sub-accounts for account ${accountId} (depth: ${depth})`);
  const subAccounts: CanvasAccount[] = [];
  
  try {
    const directSubAccounts = await makeCanvasApiRequest(userId, `/accounts/${accountId}/sub_accounts`);
    console.log(`Found ${directSubAccounts.length} direct sub-accounts for account ${accountId}`);
    
    if (directSubAccounts.length > 0) {
      subAccounts.push(...directSubAccounts);
      
      // Recursively fetch sub-accounts of each sub-account
      for (const subAccount of directSubAccounts) {
        const nestedSubAccounts = await fetchSubAccountsRecursively(userId, subAccount.id, depth + 1, maxDepth);
        subAccounts.push(...nestedSubAccounts);
      }
    }
  } catch (error) {
    console.error(`Error fetching sub-accounts for ${accountId}:`, error);
  }
  
  return subAccounts;
}

async function getAllAccounts(userId: number): Promise<CanvasAccount[]> {
  console.log('Starting to fetch Canvas accounts...');
  const allAccounts: CanvasAccount[] = [];
  
  try {
    // Get root account first using the correct endpoint
    console.log('Fetching root account...');
    const rootAccount = await makeCanvasApiRequest(userId, '/accounts/self');
    console.log('Root account fetched:', rootAccount.name, 'ID:', rootAccount.id);
    allAccounts.push(rootAccount);
    
    // Fetch all sub-accounts recursively
    const subAccounts = await fetchSubAccountsRecursively(userId, rootAccount.id);
    allAccounts.push(...subAccounts);
    
    console.log(`Total accounts fetched: ${allAccounts.length}`);
    return allAccounts;
  } catch (error) {
    console.error('Error in getAllAccounts:', error);
    throw error;
  }
}

async function createCourseInCanvas(userId: number, courseData: {
  name: string;
  course_code: string;
  account_id: string;
  start_at?: string;
  end_at?: string;
}): Promise<CanvasCourse> {
  return await makeCanvasApiRequest(userId, `/accounts/${courseData.account_id}/courses`, {
    method: 'POST',
    body: JSON.stringify({
      course: courseData,
    }),
  });
}

export async function registerRoutes(app: Express): Promise<Server> {
  // Health check endpoint
  app.get('/health', healthCheck);
  
  // Add Okta authentication routes
  app.use('/api/okta', oktaRoutes);
  
  // Main callback route (matches Okta app configuration)
  app.get('/callback', async (req: Request, res: Response) => {
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

      // Create or update user in database
      const user = await storage.upsertUser({
        oktaId: userClaims.sub,
        email: userClaims.email,
        firstName: userClaims.name.split(' ')[0] || 'Unknown',
        lastName: userClaims.name.split(' ').slice(1).join(' ') || 'User'
      });

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
  
  // Test endpoint to check Canvas API
  app.get('/api/test/canvas', async (req, res) => {
    try {
      console.log('Testing Canvas API...');
      // For testing, we'll use a dummy user ID. In production, this should be authenticated
      const testUserId = 1;
      const rootAccount = await makeCanvasApiRequest(testUserId, '/accounts/self');
      res.json({ success: true, rootAccount });
    } catch (error) {
      console.error('Canvas API test failed:', error);
      res.status(500).json({ success: false, error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Simple authentication endpoints
  app.post('/api/auth/simple-login', async (req: Request, res: Response) => {
    try {
      const { username, password } = req.body;
      
      // Define valid users
      const validUsers = [
        {
          username: 'admin',
          password: 'DPVils25!',
          oktaId: 'admin',
          email: 'tvu@digitalpromise.org',
          firstName: 'Admin',
          lastName: 'User'
        },
        {
          username: 'sbritwum',
          password: 'DPVils25!',
          oktaId: 'sbritwum',
          email: 'sbritwum@digitalpromise.org',
          firstName: 'Shibrie',
          lastName: 'Britwum'
        },
        {
          username: 'acampbell',
          password: 'DPVils25!',
          oktaId: 'acampbell',
          email: 'acampbell@digitalpromise.org',
          firstName: 'Ashley',
          lastName: 'Campbell'
        },
        {
          username: 'ewest',
          password: 'DPVils25!',
          oktaId: 'ewest',
          email: 'ewest@digitalpromise.org',
          firstName: 'Erin',
          lastName: 'West'
        },
        {
          username: 'mparkinson',
          password: 'DPVils25!',
          oktaId: 'mparkinson',
          email: 'mparkinson@digitalpromise.org',
          firstName: 'Martika',
          lastName: 'Parkinson'
        }
      ];
      
      // Find matching user
      const matchedUser = validUsers.find(user => 
        user.username === username && user.password === password
      );
      
      if (matchedUser) {
        // Create or update user in database
        const user = await storage.upsertUser({
          oktaId: matchedUser.oktaId,
          email: matchedUser.email,
          firstName: matchedUser.firstName,
          lastName: matchedUser.lastName
        });
        
        // Create session token
        const sessionToken = nanoid();
        await storage.createUserSession({
          userId: user.id,
          sessionToken: sessionToken,
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
        });
        
        res.json({
          success: true,
          token: sessionToken,
          user: {
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName
          }
        });
      } else {
        res.status(401).json({ message: 'Invalid credentials' });
      }
    } catch (error) {
      console.error("Error in simple login:", error);
      res.status(500).json({ message: "Login failed" });
    }
  });

  // Get current user endpoint - supports both Simple Auth and Okta
  app.get('/api/auth/user', async (req: Request, res: Response) => {
    try {
      // Try Okta authentication first
      const oktaSession = req.cookies.okta_session;
      if (oktaSession) {
        const userClaims = oktaSSO.verifySessionToken(oktaSession);
        if (userClaims) {
          // Get or create user in database
          let user = await storage.getUserByOktaId(userClaims.sub);
          if (!user) {
            user = await storage.upsertUser({
              oktaId: userClaims.sub,
              email: userClaims.email,
              firstName: userClaims.name.split(' ')[0] || 'Unknown',
              lastName: userClaims.name.split(' ').slice(1).join(' ') || 'User'
            });
          }
          return res.json({
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            oktaId: user.oktaId
          });
        }
      }

      // Fall back to simple auth
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ message: 'No token provided' });
      }
      
      const token = authHeader.substring(7);
      
      const session = await storage.getUserSessionByToken(token);
      
      if (!session || session.expiresAt < new Date()) {
        return res.status(401).json({ message: 'Invalid or expired token' });
      }
      
      const user = await storage.getUser(session.userId);
      
      if (!user) {
        return res.status(401).json({ message: 'User not found' });
      }
      
      res.json({
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName
      });
    } catch (error) {
      console.error('Get user error:', error);
      res.status(500).json({ message: 'Failed to get user' });
    }
  });

  // Authentication middleware - supports both Simple Auth and Okta
  const requireAuth = async (req: Request, res: Response, next: NextFunction) => {
    try {
      // Try Okta authentication first
      const oktaSession = req.cookies.okta_session;
      if (oktaSession) {
        const userClaims = oktaSSO.verifySessionToken(oktaSession);
        if (userClaims) {
          // Get or create user in database
          let user = await storage.getUserByOktaId(userClaims.sub);
          if (!user) {
            user = await storage.upsertUser({
              oktaId: userClaims.sub,
              email: userClaims.email,
              firstName: userClaims.name.split(' ')[0] || 'Unknown',
              lastName: userClaims.name.split(' ').slice(1).join(' ') || 'User'
            });
          }
          (req as AuthenticatedRequest).user = user;
          return next();
        }
      }

      // Fall back to simple auth
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ message: 'Authentication required' });
      }
      
      const token = authHeader.substring(7);
      
      const session = await storage.getUserSessionByToken(token);
      
      if (!session || session.expiresAt < new Date()) {
        return res.status(401).json({ message: 'Invalid or expired token' });
      }
      
      const user = await storage.getUser(session.userId);
      
      if (!user) {
        return res.status(401).json({ message: 'User not found' });
      }
      
      (req as AuthenticatedRequest).user = user;
      next();
    } catch (error) {
      console.error('Authentication error:', error);
      return res.status(401).json({ message: 'Authentication failed' });
    }
  };

  // Canvas OAuth endpoints
  app.get('/api/canvas/oauth/authorize', requireAuth, async (req: Request, res: Response) => {
    try {
      // Check if Canvas OAuth is configured
      const hasOAuthConfig = (process.env.CANVAS_CLIENT_ID || process.env.CANVAS_CLIENT_KEY_ID) && 
                           process.env.CANVAS_CLIENT_SECRET && 
                           process.env.CANVAS_REDIRECT_URI &&
                           process.env.CANVAS_API_URL;
      
      if (!hasOAuthConfig) {
        return res.status(400).json({ 
          message: 'Canvas OAuth is not configured. Please set up Canvas developer key and environment variables.',
          configRequired: true
        });
      }
      
      const state = nanoid(16);
      const authUrl = canvasOAuth.getAuthorizationUrl(state);
      
      // TODO: Store state in session for validation when sessions are configured
      // For now, we'll skip state validation as Canvas OAuth env vars aren't configured anyway
      
      // Return the authorization URL as JSON instead of redirecting
      res.json({ authUrl });
    } catch (error) {
      console.error('Canvas OAuth authorization error:', error);
      res.status(500).json({ message: 'Failed to start Canvas authorization' });
    }
  });

  // Canvas OAuth callback - original path
  app.get('/api/canvas/oauth/callback', async (req: Request, res: Response) => {
    try {
      const { code, state } = req.query;
      
      if (!code) {
        return res.redirect('/?canvas_auth=error&message=no_code');
      }
      
      // Exchange code for tokens
      console.log('Exchanging Canvas OAuth code for tokens...');
      const tokenResponse = await canvasOAuth.exchangeCodeForToken(code as string);
      console.log('Token exchange successful, expires_in:', tokenResponse.expires_in);
      
      // Store tokens in database for the default user (user ID 4 from logs)
      // In a production setup, you'd validate the state and associate with the proper user
      const defaultUserId = 4; // Using the user ID from the logs
      const storedToken = await canvasOAuth.storeTokens(defaultUserId, tokenResponse);
      
      console.log('Canvas OAuth tokens stored successfully for user:', defaultUserId, 'expires at:', storedToken.expiresAt);
      
      res.redirect('/?canvas_auth=success&message=oauth_configured');
    } catch (error) {
      console.error('Canvas OAuth callback error:', error);
      res.redirect('/?canvas_auth=error&message=token_exchange_failed');
    }
  });

  app.delete('/api/canvas/oauth/revoke', requireAuth, async (req: Request, res: Response) => {
    try {
      const user = (req as AuthenticatedRequest).user;
      await canvasOAuth.revokeTokens(user.id);
      res.json({ message: 'Canvas tokens revoked successfully' });
    } catch (error) {
      console.error('Canvas OAuth revoke error:', error);
      res.status(500).json({ message: 'Failed to revoke Canvas tokens' });
    }
  });

  app.get('/api/canvas/oauth/status', requireAuth, async (req: Request, res: Response) => {
    try {
      const user = (req as AuthenticatedRequest).user;
      const token = await storage.getCanvasToken(user.id);
      
      res.json({
        hasToken: !!token,
        expiresAt: token?.expiresAt,
        scope: token?.scope
      });
    } catch (error) {
      console.error('Canvas OAuth status error:', error);
      res.status(500).json({ message: 'Failed to get Canvas OAuth status' });
    }
  });

  // Get all Canvas accounts
  app.get('/api/accounts', requireAuth, async (req, res) => {
    console.log('Accounts API called');
    
    // Set a timeout for the entire request
    const timeoutId = setTimeout(() => {
      console.log('Request timeout - returning error');
      if (!res.headersSent) {
        res.status(504).json({ message: 'Request timeout' });
      }
    }, 30000); // 30 second timeout
    
    try {
      console.log('Calling getAllAccounts...');
      const user = (req as AuthenticatedRequest).user;
      const accounts = await getAllAccounts(user.id);
      
      console.log('Got accounts, storing in database...');
      // Store/update accounts in database
      for (const account of accounts) {
        await storage.upsertCanvasAccount({
          canvasId: account.id,
          name: account.name,
          parentAccountId: account.parent_account_id || null,
          workflowState: account.workflow_state,
          rootAccountId: account.root_account_id || null,
        });
      }

      clearTimeout(timeoutId);
      if (!res.headersSent) {
        console.log('Sending response with accounts');
        res.json(accounts);
      }
    } catch (error) {
      clearTimeout(timeoutId);
      console.error('Error fetching accounts:', error);
      if (!res.headersSent) {
        res.status(500).json({ message: 'Failed to fetch accounts' });
      }
    }
  });

  // Create course shells schema for frontend requests
  const courseShellRequestSchema = z.object({
    name: z.string().min(1, "Course name is required"),
    courseCode: z.string().min(1, "Course code is required"),
    startDate: z.string().optional(),
    endDate: z.string().optional(),
  });

  const createCourseShellsSchema = z.object({
    shells: z.array(courseShellRequestSchema),
    selectedAccounts: z.array(z.union([z.string(), z.number()])).transform(accounts => 
      accounts.map(account => String(account))
    ),
  });

  app.post('/api/course-shells', requireAuth, async (req: Request, res: Response) => {
    try {
      const { shells, selectedAccounts } = createCourseShellsSchema.parse(req.body);
      const user = (req as AuthenticatedRequest).user;
      const batchId = nanoid();

      // Calculate total shells to create
      const totalShells = shells.length * selectedAccounts.length;

      // Create batch record
      const batch = await storage.createCreationBatch({
        batchId,
        userId: user.id,
        totalShells,
        completedShells: 0,
        failedShells: 0,
        status: 'in_progress',
      });

      // Create course shell records
      const courseShellsToCreate = [];
      for (const accountId of selectedAccounts) {
        for (const shell of shells) {
          courseShellsToCreate.push({
            name: shell.name,
            courseCode: shell.courseCode,
            accountId,
            startDate: shell.startDate ? new Date(shell.startDate) : null,
            endDate: shell.endDate ? new Date(shell.endDate) : null,
            status: 'pending',
            createdByUserId: user.id,
            batchId,
          });
        }
      }

      const createdShells = await storage.createCourseShells(courseShellsToCreate);

      // Start async course creation process
      createCoursesAsync(createdShells, batchId, user.id);

      res.json({
        batchId,
        totalShells,
        shells: createdShells,
      });
    } catch (error) {
      console.error('Error creating course shells:', error);
      res.status(500).json({ message: 'Failed to create course shells' });
    }
  });

  // Get creation batches for a user
  app.get('/api/batches', requireAuth, async (req: Request, res: Response) => {
    try {
      const user = (req as AuthenticatedRequest).user;
      const batches = await storage.getCreationBatchesByUserId(user.id);
      res.json(batches);
    } catch (error) {
      console.error('Error fetching batches:', error);
      res.status(500).json({ message: 'Failed to fetch batches' });
    }
  });

  // Get specific batch with its course shells
  app.get('/api/batches/:batchId', requireAuth, async (req: Request, res: Response) => {
    try {
      const { batchId } = req.params;
      const user = (req as AuthenticatedRequest).user;
      
      const batch = await storage.getCreationBatchById(batchId);
      
      if (!batch || batch.userId !== user.id) {
        return res.status(404).json({ message: 'Batch not found' });
      }
      
      const courseShells = await storage.getCourseShellsByBatchId(batchId);
      
      res.json({
        batch,
        courseShells,
      });
    } catch (error) {
      console.error('Error fetching batch:', error);
      res.status(500).json({ message: 'Failed to fetch batch' });
    }
  });

  // Async function to create courses in Canvas
  async function createCoursesAsync(shells: any[], batchId: string, userId: number) {
    for (const shell of shells) {
      try {
        const courseData = {
          name: shell.name,
          course_code: shell.courseCode,
          account_id: shell.accountId,
          start_at: shell.startDate?.toISOString(),
          end_at: shell.endDate?.toISOString(),
        };

        const createdCourse = await createCourseInCanvas(userId, courseData);
        
        await storage.updateCourseShell(shell.id, {
          status: 'created',
          canvasId: createdCourse.id,
        });

        await storage.incrementBatchCompleted(batchId);
      } catch (error) {
        console.error(`Error creating course ${shell.name}:`, error);
        
        await storage.updateCourseShell(shell.id, {
          status: 'failed',
          error: error instanceof Error ? error.message : 'Unknown error',
        });

        await storage.incrementBatchFailed(batchId);
      }
    }

    // Update batch status to completed
    await storage.updateCreationBatch(batchId, { status: 'completed' });
  }

  const httpServer = createServer(app);
  return httpServer;
}