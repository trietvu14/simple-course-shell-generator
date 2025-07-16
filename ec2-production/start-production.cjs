const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('Starting Canvas Course Shell Generator...');

// Load environment variables from .env file
const envPath = path.join(__dirname, '.env');
if (fs.existsSync(envPath)) {
  console.log('Loading environment variables from .env file...');
  const envFile = fs.readFileSync(envPath, 'utf8');
  const envVars = envFile.split('\n').filter(line => line.trim() && !line.startsWith('#'));
  
  const loadedVars = [];
  envVars.forEach(line => {
    const [key, ...valueParts] = line.split('=');
    if (key && valueParts.length > 0) {
      const value = valueParts.join('=');
      process.env[key] = value;
      loadedVars.push(key);
    }
  });
  
  console.log('Environment variables loaded:', loadedVars);
} else {
  console.log('No .env file found, using system environment variables');
}

// Set production environment
process.env.NODE_ENV = 'production';
process.env.PORT = process.env.PORT || '5000';

console.log('Production server started, running development server on port', process.env.PORT);

// Start the development server (which works better with our setup)
const child = spawn('npm', ['run', 'dev'], {
  stdio: 'inherit',
  env: process.env
});

// Handle process termination
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully...');
  child.kill('SIGTERM');
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully...');
  child.kill('SIGINT');
});

child.on('exit', (code) => {
  console.log('Server exited with code', code);
  process.exit(code);
});