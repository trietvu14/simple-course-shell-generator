import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";

// Simple authentication middleware
const requireSimpleAuth = (req: any, res: any, next: any) => {
  // For simple auth, we'll just check if the user is authenticated
  // In a real app, you'd check a session or JWT token
  const authHeader = req.headers.authorization;
  
  if (!authHeader || authHeader !== 'Bearer simple-auth-token') {
    return res.status(401).json({ message: "Authentication required" });
  }
  
  // Set a simple user for the request
  req.user = {
    id: "admin",
    email: "admin@digitalpromise.org",
    firstName: "Admin",
    lastName: "User"
  };
  
  next();
};

// Simple auth login endpoint
export function setupSimpleAuth(app: Express) {
  app.post('/api/auth/simple-login', (req, res) => {
    const { username, password } = req.body;
    
    if (username === 'admin' && password === 'P@ssword01') {
      res.json({
        token: 'simple-auth-token',
        user: {
          id: "admin",
          email: "admin@digitalpromise.org",
          firstName: "Admin",
          lastName: "User"
        }
      });
    } else {
      res.status(401).json({ message: "Invalid credentials" });
    }
  });

  app.get('/api/auth/user', requireSimpleAuth, (req: any, res) => {
    res.json(req.user);
  });

  return requireSimpleAuth;
}