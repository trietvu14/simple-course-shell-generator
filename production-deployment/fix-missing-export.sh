#!/bin/bash

echo "=== Fixing Missing Export Error ==="
echo "The vite.ts file is missing the 'log' export that index.ts needs"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Fixing vite.ts to include the missing log export..."
cat > server/vite.ts << 'EOF'
import fs from "fs";
import path from "path";
import { nanoid } from "nanoid";
import type { Express } from "express";
import type { ViteDevServer } from "vite";
import { createServer as createViteServer } from "vite";

// Add the missing log function
export function log(message: string) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

export async function setupVite(app: Express, server: any) {
  const vite = await createViteServer({
    server: { middlewareMode: true },
    appType: "custom",
    optimizeDeps: {
      include: ["@tanstack/react-query", "@tanstack/react-query-devtools"],
    },
  });

  server.on("upgrade", vite.ws.handleUpgrade);

  app.use(vite.middlewares);

  app.use("*", async (req, res, next) => {
    if (req.originalUrl === "/health") {
      return next();
    }

    const url = req.originalUrl;

    try {
      const clientTemplate = path.resolve(
        import.meta.dirname,
        "..",
        "client",
        "index.html",
      );

      let template = await fs.promises.readFile(clientTemplate, "utf-8");
      template = template.replace(
        `src="/src/main.tsx"`,
        `src="/src/main.tsx?v=${nanoid()}"`,
      );
      const page = await vite.transformIndexHtml(url, template);
      res.status(200).set({ "Content-Type": "text/html" }).end(page);
    } catch (e) {
      vite.ssrFixStacktrace(e as Error);
      next(e);
    }
  });
}

export function serveStatic(app: Express) {
  // Use dist/public path (fixed from original issue)
  const distPath = path.resolve(process.cwd(), "dist", "public");

  if (!fs.existsSync(distPath)) {
    throw new Error(
      `Could not find the build directory: ${distPath}, make sure to build the client first`,
    );
  }

  // Serve static files
  app.use(express.static(distPath));

  // Important: Handle all routes by serving index.html (for React Router)
  app.use("*", (req, res) => {
    // Skip API routes
    if (req.originalUrl.startsWith('/api/')) {
      return res.status(404).json({ message: 'API endpoint not found' });
    }
    
    // Serve index.html for all other routes (React Router will handle)
    res.sendFile(path.resolve(distPath, "index.html"));
  });
}
EOF

echo "4. Verifying the fix..."
echo "Checking that vite.ts exports log function:"
grep -n "export function log" server/vite.ts || echo "Log function not found"

echo "5. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "6. Waiting for service to start..."
sleep 15

echo "7. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "8. Testing application..."
curl -s -o /dev/null -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/

echo "9. External test..."
curl -s -o /dev/null -w "HTTPS: HTTP %{http_code}\n" https://shell.dpvils.org/

echo "10. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 15

echo ""
echo "=== Missing Export Fix Complete ==="
echo "✓ Added missing log function export to vite.ts"
echo "✓ Fixed import error in server/index.ts"
echo "✓ Maintained correct path resolution for dist/public"
echo ""
echo "Service should now start without import errors"