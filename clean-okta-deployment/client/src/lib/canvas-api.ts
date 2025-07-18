import { apiRequest } from "./queryClient";

export interface CanvasAccount {
  id: string;
  name: string;
  parent_account_id?: string;
  workflow_state: string;
  root_account_id?: string;
}

export interface CourseShell {
  id: number;
  name: string;
  courseCode: string;
  canvasId?: string;
  accountId: string;
  startDate?: string;
  endDate?: string;
  status: string;
  createdByUserId: number;
  batchId?: string;
  error?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreationBatch {
  id: number;
  batchId: string;
  userId: number;
  totalShells: number;
  completedShells: number;
  failedShells: number;
  status: string;
  createdAt: string;
  updatedAt: string;
}

export interface BatchStatus {
  batch: CreationBatch;
  shells: CourseShell[];
}

export async function getCanvasAccounts(): Promise<CanvasAccount[]> {
  const response = await apiRequest("GET", "/api/accounts");
  return response.json();
}

export async function createCourseShells(data: {
  shells: Array<{
    name: string;
    courseCode: string;
    accountId: string;
    startDate?: string;
    endDate?: string;
  }>;
  selectedAccounts: string[];
}): Promise<{ batchId: string; totalShells: number; shells: CourseShell[] }> {
  const response = await apiRequest("POST", "/api/course-shells", data);
  return response.json();
}

export async function getBatchStatus(batchId: string): Promise<BatchStatus> {
  const response = await apiRequest("GET", `/api/batches/${batchId}/status`);
  return response.json();
}

export async function getRecentActivity(): Promise<CreationBatch[]> {
  const response = await apiRequest("GET", "/api/recent-activity");
  return response.json();
}
