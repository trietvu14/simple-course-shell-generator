# Definitive 502 Fix - Path Mismatch Issue

## Root Cause Identified
The application has `dist/public/index.html` but the `serveStatic` function in `server/vite.ts` looks for `server/public/index.html`.

**Path Expected**: `server/public/index.html`
**Path Actual**: `dist/public/index.html`

## Two Fix Options

### Option 1: Symlink Fix (Quick)
Run: `./fix-path-mismatch.sh`
- Creates symlink from `server/public` to `dist/public`
- Quick solution, preserves original code

### Option 2: Code Fix (Permanent)
Run: `./override-vite-config.sh`
- Modifies `server/vite.ts` to use correct path
- Changes `path.resolve(import.meta.dirname, "public")` to `path.resolve(process.cwd(), "dist", "public")`
- Permanent solution

## Recommended Approach
Try Option 1 first (symlink) as it's less invasive. If that doesn't work, use Option 2 (code fix).

## What Each Script Does

### Symlink Fix
1. Creates `server/public` symlink pointing to `dist/public`
2. Application finds files at expected location
3. Preserves original code structure

### Code Fix
1. Modifies `serveStatic` function to use `dist/public` path
2. Backs up original `vite.ts`
3. Replaces with corrected version

Both approaches solve the path mismatch that's causing the 502 error.

## Expected Results
- Service starts without path errors
- Application serves files from `dist/public`
- https://shell.dpvils.org loads successfully
- No more 502 Bad Gateway errors

The root cause is definitively a path mismatch between where files exist and where the application looks for them.