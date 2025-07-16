#!/bin/bash

cd /home/ubuntu/course-shell-generator

# Stop the service
sudo systemctl stop canvas-course-generator

# Remove corrupted build
rm -rf dist/

# Build with tsx instead of esbuild to avoid module conflicts
echo "Building with tsx..."
npx tsx --build server/index.ts --outDir dist --target node20

# If tsx build fails, try alternative build approach
if [ ! -f "dist/index.js" ]; then
    echo "tsx build failed, trying alternative approach..."
    
    # Create a simple build script that doesn't bundle
    mkdir -p dist
    cp -r server/* dist/
    cp -r shared dist/
    
    # Replace imports in dist/index.js to use relative paths
    sed -i 's/from "\.\/routes"/from ".\/routes.js"/g' dist/index.js
    sed -i 's/from "\.\/vite"/from ".\/vite.js"/g' dist/index.js
    sed -i 's/from "@shared\/schema"/from ".\/shared\/schema.js"/g' dist/index.js
fi

# If still no success, copy the source and run directly
if [ ! -f "dist/index.js" ]; then
    echo "Build failed, copying source files..."
    cp server/index.ts dist/index.js
fi

# Start the service
sudo systemctl start canvas-course-generator

# Check status
sudo systemctl status canvas-course-generator --no-pager