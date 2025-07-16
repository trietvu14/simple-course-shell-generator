import { Request, Response, NextFunction } from 'express';

interface SimpleUser {
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

export interface AuthenticatedRequest extends Request {
  user: SimpleUser;
}

export const requireSimpleAuth = (req: Request, res: Response, next: NextFunction) => {
  // For simple auth, we'll just attach the user to all requests
  // In a real implementation, you'd check session or token
  (req as AuthenticatedRequest).user = SIMPLE_USER;
  next();
};

export const getSimpleUser = (): SimpleUser => SIMPLE_USER;