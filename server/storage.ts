import { 
  users, 
  canvasAccounts, 
  courseShells, 
  creationBatches, 
  userSessions,
  type User, 
  type InsertUser,
  type CanvasAccount,
  type InsertCanvasAccount,
  type CourseShell,
  type InsertCourseShell,
  type CreationBatch,
  type InsertCreationBatch,
  type UserSession,
  type InsertUserSession
} from "@shared/schema";
import { db } from "./db";
import { eq, desc, and } from "drizzle-orm";

// Storage interface definition
export interface IStorage {
  // User methods
  getUser(id: number): Promise<User | undefined>;
  getUserByOktaId(oktaId: string): Promise<User | undefined>;
  createUser(insertUser: InsertUser): Promise<User>;
  
  // User session methods
  getUserSessionByToken(token: string): Promise<UserSession | undefined>;
  createUserSession(insertSession: InsertUserSession): Promise<UserSession>;
  
  // Canvas account methods
  upsertCanvasAccount(insertAccount: InsertCanvasAccount): Promise<CanvasAccount>;
  
  // Course shell methods
  createCourseShells(insertShells: InsertCourseShell[]): Promise<CourseShell[]>;
  updateCourseShell(id: number, updates: Partial<CourseShell>): Promise<CourseShell>;
  getCourseShellsByBatch(batchId: string): Promise<CourseShell[]>;
  
  // Creation batch methods
  createCreationBatch(insertBatch: InsertCreationBatch): Promise<CreationBatch>;
  getCreationBatch(batchId: string): Promise<CreationBatch | undefined>;
  updateCreationBatch(batchId: string, updates: Partial<CreationBatch>): Promise<CreationBatch>;
  incrementBatchCompleted(batchId: string): Promise<void>;
  incrementBatchFailed(batchId: string): Promise<void>;
  getRecentBatches(userId: number, limit: number): Promise<CreationBatch[]>;
}

export class DatabaseStorage implements IStorage {
  // User methods
  async getUser(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user || undefined;
  }

  async getUserByOktaId(oktaId: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.oktaId, oktaId));
    return user || undefined;
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const [user] = await db
      .insert(users)
      .values(insertUser)
      .returning();
    return user;
  }

  // User session methods
  async getUserSessionByToken(token: string): Promise<UserSession | undefined> {
    const [session] = await db
      .select()
      .from(userSessions)
      .where(eq(userSessions.sessionToken, token));
    return session || undefined;
  }

  async createUserSession(insertSession: InsertUserSession): Promise<UserSession> {
    const [session] = await db
      .insert(userSessions)
      .values(insertSession)
      .returning();
    return session;
  }

  // Canvas account methods
  async upsertCanvasAccount(insertAccount: InsertCanvasAccount): Promise<CanvasAccount> {
    const [existing] = await db
      .select()
      .from(canvasAccounts)
      .where(eq(canvasAccounts.canvasId, insertAccount.canvasId));

    if (existing) {
      const [updated] = await db
        .update(canvasAccounts)
        .set({
          ...insertAccount,
          updatedAt: new Date(),
        })
        .where(eq(canvasAccounts.canvasId, insertAccount.canvasId))
        .returning();
      return updated;
    }

    const [created] = await db
      .insert(canvasAccounts)
      .values(insertAccount)
      .returning();
    return created;
  }

  // Course shell methods
  async createCourseShells(insertShells: InsertCourseShell[]): Promise<CourseShell[]> {
    const shells = await db
      .insert(courseShells)
      .values(insertShells)
      .returning();
    return shells;
  }

  async updateCourseShell(id: number, updates: Partial<CourseShell>): Promise<CourseShell> {
    const [updated] = await db
      .update(courseShells)
      .set({
        ...updates,
        updatedAt: new Date(),
      })
      .where(eq(courseShells.id, id))
      .returning();
    return updated;
  }

  async getCourseShellsByBatch(batchId: string): Promise<CourseShell[]> {
    const shells = await db
      .select()
      .from(courseShells)
      .where(eq(courseShells.batchId, batchId))
      .orderBy(courseShells.createdAt);
    return shells;
  }

  // Creation batch methods
  async createCreationBatch(insertBatch: InsertCreationBatch): Promise<CreationBatch> {
    const [batch] = await db
      .insert(creationBatches)
      .values(insertBatch)
      .returning();
    return batch;
  }

  async getCreationBatch(batchId: string): Promise<CreationBatch | undefined> {
    const [batch] = await db
      .select()
      .from(creationBatches)
      .where(eq(creationBatches.batchId, batchId));
    return batch || undefined;
  }

  async updateCreationBatch(batchId: string, updates: Partial<CreationBatch>): Promise<CreationBatch> {
    const [updated] = await db
      .update(creationBatches)
      .set({
        ...updates,
        updatedAt: new Date(),
      })
      .where(eq(creationBatches.batchId, batchId))
      .returning();
    return updated;
  }

  async incrementBatchCompleted(batchId: string): Promise<void> {
    const [batch] = await db
      .select()
      .from(creationBatches)
      .where(eq(creationBatches.batchId, batchId));
    
    if (batch) {
      await db
        .update(creationBatches)
        .set({
          completedShells: batch.completedShells + 1,
          updatedAt: new Date(),
        })
        .where(eq(creationBatches.batchId, batchId));
    }
  }

  async incrementBatchFailed(batchId: string): Promise<void> {
    const [batch] = await db
      .select()
      .from(creationBatches)
      .where(eq(creationBatches.batchId, batchId));
    
    if (batch) {
      await db
        .update(creationBatches)
        .set({
          failedShells: batch.failedShells + 1,
          updatedAt: new Date(),
        })
        .where(eq(creationBatches.batchId, batchId));
    }
  }

  async getRecentBatches(userId: number, limit: number): Promise<CreationBatch[]> {
    const batches = await db
      .select()
      .from(creationBatches)
      .where(eq(creationBatches.userId, userId))
      .orderBy(desc(creationBatches.createdAt))
      .limit(limit);
    return batches;
  }
}

export const storage = new DatabaseStorage();