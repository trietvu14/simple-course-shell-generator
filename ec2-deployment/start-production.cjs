#!/usr/bin/env node

// Simple production starter that just runs the development server
// This avoids ES module issues and uses the existing working setup

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

console.log('Starting Canvas Course Shell Generator...');

// Change to the project directory
const projectDir = '/home/ubuntu/canvas-course-generator';
process.chdir(projectDir);

// Load .env file manually
const envPath = path.join(process.cwd(), '.env');
if (fs.existsSync(envPath)) {
  console.log('Loading environment variables from .env file...');
  const envContent = fs.readFileSync(envPath, 'utf8');
  
  envContent.split('\n').forEach(line => {
    const [key, ...valueParts] = line.split('=');
    if (key && valueParts.length > 0) {
      const value = valueParts.join('=').trim();
      if (value && !key.startsWith('#')) {
        process.env[key.trim()] = value;
      }
    }
  });
  
  console.log('Environment variables loaded:', Object.keys(process.env).filter(key => 
    ['DATABASE_URL', 'CANVAS_API_TOKEN', 'OKTA_CLIENT_ID', 'PORT', 'NODE_ENV'].includes(key)
  ));
} else {
  console.warn('No .env file found at:', envPath);
}

// Set environment variables
process.env.NODE_ENV = 'production';
process.env.PORT = process.env.PORT || '5000';

// Start the development server (which includes both API and React)
const server = spawn('npm', ['run', 'dev'], {
  stdio: 'inherit',
  env: process.env
});

server.on('error', (error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});

server.on('close', (code) => {
  console.log(`Server exited with code ${code}`);
  process.exit(code);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully...');
  server.kill('SIGTERM');
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully...');
  server.kill('SIGINT');
});

console.log('Production server started, running development server on port', process.env.PORT);