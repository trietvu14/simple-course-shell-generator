import { Request, Response } from 'express';
import { pool } from './db';

export async function healthCheck(req: Request, res: Response) {
  try {
    // Check database connection
    const dbResult = await pool.query('SELECT 1');
    
    // Check if Canvas API credentials are configured
    const canvasConfigured = !!(process.env.CANVAS_API_URL && process.env.CANVAS_API_TOKEN);
    
    // Check if Okta is configured
    const oktaConfigured = !!(process.env.OKTA_CLIENT_ID && process.env.OKTA_CLIENT_SECRET && process.env.OKTA_ISSUER);
    
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      uptime: process.uptime(),
      database: {
        status: 'connected',
        type: 'postgresql'
      },
      canvas: {
        configured: canvasConfigured,
        url: process.env.CANVAS_API_URL || 'not configured'
      },
      okta: {
        configured: oktaConfigured,
        issuer: process.env.OKTA_ISSUER || 'not configured'
      },
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
        unit: 'MB'
      }
    };
    
    res.status(200).json(health);
  } catch (error) {
    console.error('Health check failed:', error);
    
    const health = {
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error',
      database: {
        status: 'disconnected'
      }
    };
    
    res.status(503).json(health);
  }
}