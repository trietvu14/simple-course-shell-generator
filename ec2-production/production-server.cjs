#!/usr/bin/env node

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('Starting Canvas Course Shell Generator...');

// Load environment variables
const dotenv = require('dotenv');
const envPath = path.join(__dirname, '.env');

if (fs.existsSync(envPath)) {
    console.log('Loading environment variables from .env file...');
    dotenv.config({ path: envPath });
    
    // Log loaded environment variables (without sensitive values)
    const envVars = Object.keys(process.env).filter(key => 
        key.startsWith('NODE_') || 
        key.startsWith('PORT') ||
        key.startsWith('DATABASE_') ||
        key.startsWith('CANVAS_') ||
        key.startsWith('OKTA_') ||
        key.startsWith('SESSION_') ||
        key.startsWith('LOG_') ||
        key.startsWith('MAX_') ||
        key.startsWith('SSL_') ||
        key.startsWith('ENABLE_') ||
        key.startsWith('METRICS_') ||
        key.startsWith('RATE_') ||
        key.startsWith('VITE_')
    );
    console.log('Environment variables loaded:', envVars);
} else {
    console.warn('.env file not found, using system environment variables only');
}

// Set production environment
process.env.NODE_ENV = 'production';

// Start the server using node directly with the compiled JavaScript
console.log('Production server started, running server on port', process.env.PORT || 5000);

// Use npx to run tsx if it's available in node_modules
const serverProcess = spawn('npx', ['tsx', 'server/index.ts'], {
    stdio: 'inherit',
    env: process.env,
    cwd: __dirname
});

serverProcess.on('error', (error) => {
    console.error('Failed to start server:', error);
    process.exit(1);
});

serverProcess.on('exit', (code) => {
    console.log(`Server exited with code ${code}`);
    process.exit(code);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
    console.log('Received SIGTERM, shutting down gracefully...');
    serverProcess.kill('SIGTERM');
});

process.on('SIGINT', () => {
    console.log('Received SIGINT, shutting down gracefully...');
    serverProcess.kill('SIGINT');
});