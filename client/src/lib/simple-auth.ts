// Simple authentication for testing without Okta
export interface SimpleUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
}

const SIMPLE_USER: SimpleUser = {
  id: "admin",
  email: "admin@digitalpromise.org",
  firstName: "Admin",
  lastName: "User"
};

export function authenticateSimple(username: string, password: string): boolean {
  return username === "admin" && password === "P@ssword01";
}

export function getSimpleUser(): SimpleUser {
  return SIMPLE_USER;
}

export function isSimpleAuthEnabled(): boolean {
  // Force simple auth for production deployment
  return true;
}