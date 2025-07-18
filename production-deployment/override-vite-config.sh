#!/bin/bash

echo "=== Overriding Vite Configuration for Production ==="
echo "Modifying server code to use correct path"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Going to application directory..."
cd "$TARGET_DIR"

echo "3. Creating fixed vite.ts that uses correct path..."
cat > server/vite-fixed.ts << 'EOF'
import fs from "fs";
import path from "path";
import { nanoid } from "nanoid";
import type { Express } from "express";
import type { ViteDevServer } from "vite";
import { createServer as createViteServer } from "vite";

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
  // Fixed: Use dist/public instead of server/public
  const distPath = path.resolve(process.cwd(), "dist", "public");

  if (!fs.existsSync(distPath)) {
    throw new Error(
      `Could not find the build directory: ${distPath}, make sure to build the client first`,
    );
  }

  app.use(express.static(distPath));

  // fall through to index.html if the file doesn't exist
  app.use("*", (_req, res) => {
    res.sendFile(path.resolve(distPath, "index.html"));
  });
}
EOF

echo "4. Backing up original vite.ts..."
cp server/vite.ts server/vite.ts.backup

echo "5. Replacing with fixed version..."
cp server/vite-fixed.ts server/vite.ts

echo "6. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "7. Waiting for service..."
sleep 15

echo "8. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "9. Testing application..."
curl -s -o /dev/null -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/

echo "10. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Vite Configuration Override Complete ==="
echo "Modified serveStatic to use dist/public instead of server/public"
echo "This should resolve the path issue definitively"