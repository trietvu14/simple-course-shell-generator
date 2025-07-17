import type { Express, Request, Response, NextFunction } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { z } from "zod";
import { insertCreationBatchSchema, type User } from "@shared/schema";
import { nanoid } from "nanoid";
import { healthCheck } from "./health";
import { canvasOAuth } from "./canvas-oauth";

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
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
  
  try {
    const response = await canvasOAuth.makeCanvasApiRequest(userId, endpoint, {
      ...options,
      signal: controller.signal,
    });

    clearTimeout(timeoutId);
    return response;
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
      
      if (username === 'admin' && password === 'P@ssword01') {
        // Create or update user in database
        const user = await storage.upsertUser({
          oktaId: 'admin',
          email: 'admin@digitalpromise.org',
          firstName: 'Admin',
          lastName: 'User'
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

  // Get current user endpoint
  app.get('/api/auth/user', async (req: Request, res: Response) => {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No token provided' });
    }
    
    const token = authHeader.substring(7);
    
    try {
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

  // Authentication middleware - requires Bearer token
  const requireAuth = async (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Authentication required' });
    }
    
    const token = authHeader.substring(7);
    
    try {
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
      createCoursesAsync(createdShells, batchId);

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

  // Get batch status
  app.get('/api/batches/:batchId/status', requireAuth, async (req, res) => {
    try {
      const { batchId } = req.params;
      const batch = await storage.getCreationBatch(batchId);
      
      if (!batch) {
        return res.status(404).json({ message: 'Batch not found' });
      }

      const shells = await storage.getCourseShellsByBatch(batchId);
      
      res.json({
        batch,
        shells,
      });
    } catch (error) {
      console.error('Error fetching batch status:', error);
      res.status(500).json({ message: 'Failed to fetch batch status' });
    }
  });

  // Get user's recent activity
  app.get('/api/recent-activity', requireAuth, async (req: Request, res: Response) => {
    try {
      const user = (req as AuthenticatedRequest).user;
      const batches = await storage.getRecentBatches(user.id, 10);
      res.json(batches);
    } catch (error) {
      console.error('Error fetching recent activity:', error);
      res.status(500).json({ message: 'Failed to fetch recent activity' });
    }
  });

  // Okta user creation/login callback
  app.post('/api/auth/okta-callback', async (req, res) => {
    try {
      const { oktaId, email, firstName, lastName } = req.body;
      
      if (!oktaId || !email) {
        return res.status(400).json({ message: 'Missing required user information' });
      }
      
      let user = await storage.getUserByOktaId(oktaId);
      
      if (!user) {
        user = await storage.createUser({
          oktaId,
          email,
          firstName: firstName || '',
          lastName: lastName || '',
        });
      }

      res.json(user);
    } catch (error) {
      console.error('Error in Okta callback:', error);
      res.status(500).json({ message: 'Authentication failed' });
    }
  });

  // Simple login with hardcoded credentials
  app.post('/api/auth/login', async (req, res) => {
    try {
      const { username, password } = req.body;
      
      // Hardcoded credentials for testing
      const VALID_USERNAME = "admin";
      const VALID_PASSWORD = "password123";
      
      if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required' });
      }
      
      if (username !== VALID_USERNAME || password !== VALID_PASSWORD) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      const testUser = {
        oktaId: 'test-admin-id',
        email: 'admin@powerfullearning.com',
        firstName: 'Admin',
        lastName: 'User',
      };

      let user = await storage.getUserByOktaId(testUser.oktaId);
      
      if (!user) {
        user = await storage.createUser(testUser);
      }

      const sessionToken = nanoid();
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

      await storage.createUserSession({
        userId: user.id,
        sessionToken,
        expiresAt,
      });

      res.json({
        user,
        sessionToken,
        expiresAt,
      });
    } catch (error) {
      console.error('Error in login:', error);
      res.status(500).json({ message: 'Login failed' });
    }
  });

  // Async function to create courses in Canvas
  async function createCoursesAsync(shells: any[], batchId: string) {
    for (const shell of shells) {
      try {
        const courseData = {
          name: shell.name,
          course_code: shell.courseCode,
          account_id: shell.accountId,
          start_at: shell.startDate?.toISOString(),
          end_at: shell.endDate?.toISOString(),
        };

        const createdCourse = await createCourseInCanvas(shell.createdByUserId, courseData);
        
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
