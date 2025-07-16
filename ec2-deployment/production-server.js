import express from 'express';
import path from 'path';
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// Load environment variables
import 'dotenv/config';

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start the development server (which includes both API and React)
console.log('Starting development server...');
const devServer = spawn('npm', ['run', 'dev'], {
  stdio: 'inherit',
  env: { ...process.env, NODE_ENV: 'development' }
});

devServer.on('close', (code) => {
  console.log(`Development server exited with code ${code}`);
  process.exit(code);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully...');
  devServer.kill();
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully...');
  devServer.kill();
});

console.log('Production server started, delegating to development server on port', PORT);
