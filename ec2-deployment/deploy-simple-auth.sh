#!/bin/bash

echo "=== Canvas Course Shell Generator - Simple Auth Deployment ==="
echo "Deploying version with simple authentication for testing..."

TARGET_DIR="/home/ubuntu/canvas-course-generator"

# Stop the service
echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

# Backup current files
echo "2. Creating backup..."
mkdir -p "$TARGET_DIR/backup-simple-$(date +%Y%m%d-%H%M%S)"
cp -r "$TARGET_DIR/client/src" "$TARGET_DIR/backup-simple-$(date +%Y%m%d-%H%M%S)/" 2>/dev/null || true

# Copy all files
echo "3. Copying simple auth files..."
cp -r client/* "$TARGET_DIR/client/"
cp -r server/* "$TARGET_DIR/server/"
cp -r attached_assets/* "$TARGET_DIR/attached_assets/" 2>/dev/null || true
cp .env "$TARGET_DIR/.env"

# Create main.tsx to use simple auth
echo "4. Configuring for simple auth..."
cat > "$TARGET_DIR/client/src/main.tsx" << 'EOF'
import { createRoot } from "react-dom/client";
import App from "./App-simple";
import "./index.css";

createRoot(document.getElementById("root")!).render(<App />);
EOF

# Update server index to use simple routes
cat > "$TARGET_DIR/server/index.ts" << 'EOF'
import express, { type Request, Response, NextFunction } from "express";
import { registerSimpleRoutes } from "./routes-simple";
import { setupVite, serveStatic, log } from "./vite";
import { healthCheck } from "./health";

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Health check endpoint
app.get("/health", healthCheck);

// Setup routes
registerSimpleRoutes(app).then((server) => {
  // Error handling middleware
  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Internal Server Error";
    
    log(`Error ${status}: ${message}`);
    res.status(status).json({ message });
  });

  // Setup Vite in development or serve static files in production
  if (process.env.NODE_ENV === "development") {
    setupVite(app, server);
  } else {
    serveStatic(app);
  }

  const PORT = process.env.PORT || 5000;
  server.listen(PORT, "0.0.0.0", () => {
    log(`serving on port ${PORT}`);
  });
});
EOF

# Set permissions
echo "5. Setting permissions..."
sudo chown -R ubuntu:ubuntu "$TARGET_DIR"
sudo chmod -R 755 "$TARGET_DIR"

# Clear caches
echo "6. Clearing caches..."
cd "$TARGET_DIR"
rm -rf dist/
rm -rf node_modules/.vite/
rm -rf node_modules/.cache/

# Start the service
echo "7. Starting service..."
sudo systemctl start canvas-course-generator.service

# Wait and check status
echo "8. Checking service status..."
sleep 10
sudo systemctl status canvas-course-generator.service --no-pager -l

echo ""
echo "=== Simple Auth Deployment Complete ==="
echo "The application now uses simple authentication:"
echo "✓ Username: admin"
echo "✓ Password: P@ssword01"
echo "✓ No Okta integration required"
echo "✓ All Canvas functionality preserved"
echo ""
echo "Access the application at: https://shell.dpvils.org"
echo "Login with the credentials above to test Canvas course creation."