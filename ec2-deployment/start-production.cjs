#!/usr/bin/env node

// Simple production starter that just runs the development server
// This avoids ES module issues and uses the existing working setup

const { spawn } = require('child_process');
const path = require('path');

console.log('Starting Canvas Course Shell Generator...');

// Change to the project directory
process.chdir('/home/ubuntu/canvas-course-generator');

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