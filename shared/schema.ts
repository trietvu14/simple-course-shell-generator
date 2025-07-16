import { pgTable, text, serial, integer, boolean, timestamp, jsonb } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  oktaId: text("okta_id").notNull().unique(),
  email: text("email").notNull().unique(),
  firstName: text("first_name").notNull(),
  lastName: text("last_name").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const canvasAccounts = pgTable("canvas_accounts", {
  id: serial("id").primaryKey(),
  canvasId: text("canvas_id").notNull().unique(),
  name: text("name").notNull(),
  parentAccountId: text("parent_account_id"),
  workflowState: text("workflow_state").notNull(),
  rootAccountId: text("root_account_id"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const courseShells = pgTable("course_shells", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  courseCode: text("course_code").notNull(),
  canvasId: text("canvas_id").unique(),
  accountId: text("account_id").notNull(),
  startDate: timestamp("start_date"),
  endDate: timestamp("end_date"),
  status: text("status").notNull().default("pending"), // pending, created, failed
  createdByUserId: integer("created_by_user_id").notNull(),
  batchId: text("batch_id"),
  error: text("error"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const creationBatches = pgTable("creation_batches", {
  id: serial("id").primaryKey(),
  batchId: text("batch_id").notNull().unique(),
  userId: integer("user_id").notNull(),
  totalShells: integer("total_shells").notNull(),
  completedShells: integer("completed_shells").notNull().default(0),
  failedShells: integer("failed_shells").notNull().default(0),
  status: text("status").notNull().default("in_progress"), // in_progress, completed, failed
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export const userSessions = pgTable("user_sessions", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull(),
  sessionToken: text("session_token").notNull().unique(),
  expiresAt: timestamp("expires_at").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// Relations
export const usersRelations = relations(users, ({ many }) => ({
  courseShells: many(courseShells),
  creationBatches: many(creationBatches),
  userSessions: many(userSessions),
}));

export const courseShellsRelations = relations(courseShells, ({ one }) => ({
  createdBy: one(users, {
    fields: [courseShells.createdByUserId],
    references: [users.id],
  }),
}));

export const creationBatchesRelations = relations(creationBatches, ({ one }) => ({
  user: one(users, {
    fields: [creationBatches.userId],
    references: [users.id],
  }),
}));

export const userSessionsRelations = relations(userSessions, ({ one }) => ({
  user: one(users, {
    fields: [userSessions.userId],
    references: [users.id],
  }),
}));

// Insert schemas
export const insertUserSchema = createInsertSchema(users).omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

export const insertCanvasAccountSchema = createInsertSchema(canvasAccounts).omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

export const insertCourseShellSchema = createInsertSchema(courseShells).omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

export const insertCreationBatchSchema = createInsertSchema(creationBatches).omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

export const insertUserSessionSchema = createInsertSchema(userSessions).omit({
  id: true,
  createdAt: true,
});

// Types
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;
export type CanvasAccount = typeof canvasAccounts.$inferSelect;
export type InsertCanvasAccount = z.infer<typeof insertCanvasAccountSchema>;
export type CourseShell = typeof courseShells.$inferSelect;
export type InsertCourseShell = z.infer<typeof insertCourseShellSchema>;
export type CreationBatch = typeof creationBatches.$inferSelect;
export type InsertCreationBatch = z.infer<typeof insertCreationBatchSchema>;
export type UserSession = typeof userSessions.$inferSelect;
export type InsertUserSession = z.infer<typeof insertUserSessionSchema>;
