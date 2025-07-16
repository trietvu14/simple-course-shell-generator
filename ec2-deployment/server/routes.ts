import type { Express, Request, Response, NextFunction } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { z } from "zod";
import { insertCreationBatchSchema, type User } from "@shared/schema";
import { nanoid } from "nanoid";
import { healthCheck } from "./health";

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

async function makeCanvasApiRequest(endpoint: string, options: RequestInit = {}) {
  const { CANVAS_API_URL, CANVAS_API_TOKEN } = getCanvasConfig();
  
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
  
  try {
    const response = await fetch(`${CANVAS_API_URL}${endpoint}`, {
      ...options,
      signal: controller.signal,
      headers: {
        'Authorization': `Bearer ${CANVAS_API_TOKEN}`,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`Canvas API error: ${response.status} ${response.statusText}`);
    }

    return response.json();
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}

async function fetchSubAccountsRecursively(accountId: string, depth: number = 0, maxDepth: number = 5): Promise<CanvasAccount[]> {
  if (depth > maxDepth) {
    console.log(`Max depth ${maxDepth} reached for account ${accountId}, skipping`);
    return [];
  }
  
  console.log(`Fetching sub-accounts for account ${accountId} (depth: ${depth})`);
  const subAccounts: CanvasAccount[] = [];
  
  try {
    const directSubAccounts = await makeCanvasApiRequest(`/accounts/${accountId}/sub_accounts`);
    console.log(`Found ${directSubAccounts.length} direct sub-accounts for account ${accountId}`);
    
    if (directSubAccounts.length > 0) {
      subAccounts.push(...directSubAccounts);
      
      // Recursively fetch sub-accounts of each sub-account
      for (const subAccount of directSubAccounts) {
        const nestedSubAccounts = await fetchSubAccountsRecursively(subAccount.id, depth + 1, maxDepth);
        subAccounts.push(...nestedSubAccounts);
      }
    }
  } catch (error) {
    console.error(`Error fetching sub-accounts for ${accountId}:`, error);
  }
  
  return subAccounts;
}

async function getAllAccounts(): Promise<CanvasAccount[]> {
  console.log('Starting to fetch Canvas accounts...');
  const allAccounts: CanvasAccount[] = [];
  
  try {
    // Get root account first using the correct endpoint
    console.log('Fetching root account...');
    const rootAccount = await makeCanvasApiRequest('/accounts/self');
    console.log('Root account fetched:', rootAccount.name, 'ID:', rootAccount.id);
    allAccounts.push(rootAccount);
    
    // Fetch all sub-accounts recursively
    const subAccounts = await fetchSubAccountsRecursively(rootAccount.id);
    allAccounts.push(...subAccounts);
    
    console.log(`Total accounts fetched: ${allAccounts.length}`);
    return allAccounts;
  } catch (error) {
    console.error('Error in getAllAccounts:', error);
    throw error;
  }
}

async function createCourseInCanvas(courseData: {
  name: string;
  course_code: string;
  account_id: string;
  start_at?: string;
  end_at?: string;
}): Promise<CanvasCourse> {
  return await makeCanvasApiRequest(`/accounts/${courseData.account_id}/courses`, {
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
      const rootAccount = await makeCanvasApiRequest('/accounts/self');
      res.json({ success: true, rootAccount });
    } catch (error) {
      console.error('Canvas API test failed:', error);
      res.status(500).json({ success: false, error: error instanceof Error ? error.message : 'Unknown error' });
    }
  });

  // Okta callback endpoint - handles user registration/login
  app.post('/api/auth/okta-callback', async (req: Request, res: Response) => {
    try {
      const { oktaId, email, firstName, lastName } = req.body;
      
      if (!oktaId) {
        return res.status(400).json({ message: 'Okta ID is required' });
      }
      
      // Create or update user in database
      const user = await storage.upsertUser({
        oktaId,
        email: email || `${oktaId}@digitalpromise.org`,
        firstName: firstName || 'Unknown',
        lastName: lastName || 'User'
      });
      
      res.json(user);
    } catch (error) {
      console.error("Error in Okta callback:", error);
      res.status(500).json({ message: "Failed to process Okta callback" });
    }
  });

  // Authentication middleware - requires Okta user in localStorage
  const requireAuth = async (req: Request, res: Response, next: NextFunction) => {
    const oktaUserHeader = req.headers['x-okta-user'] as string;
    
    if (!oktaUserHeader) {
      return res.status(401).json({ message: 'Authentication required' });
    }
    
    try {
      const oktaUser = JSON.parse(oktaUserHeader);
      const oktaId = oktaUser.sub;
      
      if (!oktaId) {
        return res.status(401).json({ message: 'Invalid authentication token' });
      }
      
      let user = await storage.getUserByOktaId(oktaId);
      
      // If user doesn't exist, create from Okta info
      if (!user) {
        const newUser = {
          oktaId: oktaId,
          email: oktaUser.email || `${oktaId}@digitalpromise.org`,
          firstName: oktaUser.given_name || 'Unknown',
          lastName: oktaUser.family_name || 'User'
        };
        user = await storage.upsertUser(newUser);
        console.log('Created new user from Okta:', user);
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
      const accounts = await getAllAccounts();
      
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

        const createdCourse = await createCourseInCanvas(courseData);
        
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
