const express = require('express');
const path = require('path');
const { createServer } = require('http');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'production'
  });
});

// API routes
app.get('/api/test', (req, res) => {
  res.json({ message: 'API is working', timestamp: new Date().toISOString() });
});

// Serve static files if they exist
const staticPath = path.join(__dirname, 'dist');
app.use(express.static(staticPath));

// Fallback route - serve a simple HTML page
app.get('*', (req, res) => {
  const fallbackHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canvas Course Shell Generator</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 40px;
            background: #f5f5f5;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header { 
            text-align: center; 
            margin-bottom: 30px;
        }
        .status { 
            background: #e8f5e8;
            border: 1px solid #4caf50;
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
        }
        .info { 
            background: #e3f2fd;
            border: 1px solid #2196f3;
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
        }
        .button {
            background: #2196f3;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin: 10px;
        }
        .button:hover {
            background: #1976d2;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Canvas Course Shell Generator</h1>
            <p>Digital Promise Educational Technology Platform</p>
        </div>
        
        <div class="status">
            <strong>✓ System Status:</strong> Online and Running
        </div>
        
        <div class="info">
            <strong>ℹ️ Application Loading:</strong> 
            The full React application is initializing. This temporary page shows the system is working.
        </div>
        
        <div style="text-align: center; margin-top: 30px;">
            <a href="/health" class="button">Check System Health</a>
            <a href="/api/test" class="button">Test API</a>
        </div>
        
        <div style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; text-align: center; color: #666;">
            <p>Server Time: ${new Date().toISOString()}</p>
            <p>Environment: ${process.env.NODE_ENV || 'production'}</p>
        </div>
    </div>
</body>
</html>`;
  
  res.send(fallbackHtml);
});

const server = createServer(app);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Canvas Course Shell Generator running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`Server started at: ${new Date().toISOString()}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});