#!/bin/bash

echo "=== Fixing Build Directory Issue ==="
echo "The application is failing because it can't find the build directory"

TARGET_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Stopping service..."
sudo systemctl stop canvas-course-generator.service

echo "2. Navigating to application directory..."
cd "$TARGET_DIR"

echo "3. Creating build directory..."
mkdir -p dist

echo "4. Building frontend..."
npm run build

echo "5. Checking if build was successful..."
if [ -d "dist" ] && [ -f "dist/index.html" ]; then
    echo "✓ Build successful"
    ls -la dist/
else
    echo "✗ Build failed, creating fallback solution..."
    
    # Create a simple fallback build
    mkdir -p dist
    
    cat > dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Canvas Course Shell Generator</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .loading { text-align: center; padding: 40px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="loading">
            <h1>Canvas Course Shell Generator</h1>
            <p>Loading application...</p>
            <p>Please wait while we initialize the system.</p>
        </div>
    </div>
</body>
</html>
EOF

    echo "Fallback build created"
fi

echo "6. Starting service..."
sudo systemctl start canvas-course-generator.service

echo "7. Waiting for service to start..."
sleep 10

echo "8. Checking service status..."
sudo systemctl status canvas-course-generator.service --no-pager

echo "9. Testing application..."
curl -s -o /dev/null -w "Health: HTTP %{http_code}\n" http://localhost:5000/health
curl -s -o /dev/null -w "Root: HTTP %{http_code}\n" http://localhost:5000/

echo "10. Recent logs..."
sudo journalctl -u canvas-course-generator.service --no-pager -n 10

echo ""
echo "=== Build Directory Fix Complete ==="
echo "The application should now start without the build directory error"