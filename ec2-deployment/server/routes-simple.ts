import type { Express } from "express";
import { createServer, type Server } from "http";
import { z } from "zod";
import { nanoid } from "nanoid";
import { requireSimpleAuth, type AuthenticatedRequest } from "./simple-auth";
import { storage } from "./storage";

export async function registerSimpleRoutes(app: Express): Promise<Server> {
  // Simple auth endpoint
  app.get('/api/auth/user', requireSimpleAuth, async (req: Request, res: Response) => {
    const user = (req as AuthenticatedRequest).user;
    res.json(user);
  });

  // Canvas API configuration
  function getCanvasConfig() {
    const CANVAS_API_URL = process.env.CANVAS_API_URL || "https://dppowerfullearning.instructure.com/api/v1";
    const CANVAS_API_TOKEN = process.env.CANVAS_API_TOKEN || "";
    
    return { CANVAS_API_URL, CANVAS_API_TOKEN };
  }

  // Canvas API helper function
  async function makeCanvasApiRequest(endpoint: string, options: RequestInit = {}) {
    const { CANVAS_API_URL, CANVAS_API_TOKEN } = getCanvasConfig();
    
    const url = `${CANVAS_API_URL}${endpoint}`;
    const headers = {
      'Authorization': `Bearer ${CANVAS_API_TOKEN}`,
      'Content-Type': 'application/json',
      ...options.headers,
    };

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      throw new Error(`Canvas API request failed: ${response.status} ${response.statusText}`);
    }

    return response;
  }

  // Get Canvas accounts
  app.get('/api/accounts', requireSimpleAuth, async (req: Request, res: Response) => {
    try {
      const response = await makeCanvasApiRequest('/accounts');
      const accounts = await response.json();
      res.json(accounts);
    } catch (error) {
      console.error('Error fetching accounts:', error);
      res.status(500).json({ message: 'Failed to fetch accounts' });
    }
  });

  // Create course shells
  const createCourseShellsSchema = z.object({
    shells: z.array(z.object({
      name: z.string().min(1, "Course name is required"),
      courseCode: z.string().min(1, "Course code is required"),
      startDate: z.string().optional(),
      endDate: z.string().optional(),
    })),
    selectedAccounts: z.array(z.string()),
  });

  app.post('/api/course-shells', requireSimpleAuth, async (req: Request, res: Response) => {
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

      // Create shell records
      const shellRecords = [];
      for (const account of selectedAccounts) {
        for (const shell of shells) {
          shellRecords.push({
            name: shell.name,
            courseCode: shell.courseCode,
            accountId: account,
            batchId,
            status: 'pending' as const,
            startDate: shell.startDate ? new Date(shell.startDate) : undefined,
            endDate: shell.endDate ? new Date(shell.endDate) : undefined,
          });
        }
      }

      await storage.createCourseShells(shellRecords);

      res.json({ batchId, totalShells });

      // Start async course creation
      createCoursesAsync(shellRecords, batchId);
    } catch (error) {
      console.error('Error creating course shells:', error);
      res.status(500).json({ message: 'Failed to create course shells' });
    }
  });

  // Async course creation function
  async function createCoursesAsync(shells: any[], batchId: string) {
    for (const shell of shells) {
      try {
        const courseData = {
          name: shell.name,
          course_code: shell.courseCode,
          start_at: shell.startDate,
          end_at: shell.endDate,
        };

        const response = await makeCanvasApiRequest(`/accounts/${shell.accountId}/courses`, {
          method: 'POST',
          body: JSON.stringify({ course: courseData }),
        });

        const course = await response.json();

        await storage.updateCourseShell(shell.id, {
          status: 'completed',
          canvasId: course.id,
        });

        await storage.incrementBatchCompleted(batchId);
      } catch (error) {
        console.error(`Error creating course ${shell.name}:`, error);
        
        await storage.updateCourseShell(shell.id, {
          status: 'failed',
          errorMessage: error.message,
        });

        await storage.incrementBatchFailed(batchId);
      }
    }

    // Update batch status
    const batch = await storage.getCreationBatch(batchId);
    if (batch) {
      const isComplete = batch.completedShells + batch.failedShells >= batch.totalShells;
      if (isComplete) {
        await storage.updateCreationBatch(batchId, {
          status: batch.failedShells > 0 ? 'completed_with_errors' : 'completed',
        });
      }
    }
  }

  // Get batch status
  app.get('/api/batches/:batchId', requireSimpleAuth, async (req: Request, res: Response) => {
    try {
      const { batchId } = req.params;
      const batch = await storage.getCreationBatch(batchId);
      
      if (!batch) {
        return res.status(404).json({ message: 'Batch not found' });
      }

      const shells = await storage.getCourseShellsByBatch(batchId);
      
      res.json({ batch, shells });
    } catch (error) {
      console.error('Error fetching batch:', error);
      res.status(500).json({ message: 'Failed to fetch batch' });
    }
  });

  // Get recent activity
  app.get('/api/recent-activity', requireSimpleAuth, async (req: Request, res: Response) => {
    try {
      const user = (req as AuthenticatedRequest).user;
      const batches = await storage.getRecentBatches(user.id, 10);
      res.json(batches);
    } catch (error) {
      console.error('Error fetching recent activity:', error);
      res.status(500).json({ message: 'Failed to fetch recent activity' });
    }
  });

  const httpServer = createServer(app);
  return httpServer;
}