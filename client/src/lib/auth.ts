// This file is deprecated - authentication is now handled by Okta
// Keeping for backwards compatibility during migration

export interface User {
  id: number;
  oktaId: string;
  email: string;
  firstName: string;
  lastName: string;
}

export interface AuthResponse {
  user: User;
  sessionToken: string;
  expiresAt: string;
}

// Deprecated - use Okta authentication instead
export async function login(username: string, password: string): Promise<AuthResponse> {
  throw new Error("Login method deprecated - use Okta authentication");
}

export function getAuthToken(): string | null {
  return null; // Deprecated
}

export function setAuthToken(token: string): void {
  // Deprecated
}

export function removeAuthToken(): void {
  // Deprecated
}

export function getStoredUser(): User | null {
  return null; // Deprecated
}

export function setStoredUser(user: User): void {
  // Deprecated
}

export function removeStoredUser(): void {
  // Deprecated
}

export function logout(): void {
  // Deprecated - use Okta logout instead
}
