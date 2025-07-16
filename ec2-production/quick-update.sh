#!/bin/bash

echo "=== Quick Update: Simple Authentication ==="

# Just update the key files for simple auth
APP_DIR="/home/ubuntu/canvas-course-generator"

echo "1. Updating authentication files..."

# Update the simple auth detection
sudo tee "$APP_DIR/client/src/lib/simple-auth.ts" > /dev/null << 'EOF'
// Simple authentication for testing without Okta
export interface SimpleUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
}

const SIMPLE_USER: SimpleUser = {
  id: "admin",
  email: "admin@digitalpromise.org",
  firstName: "Admin",
  lastName: "User"
};

export function authenticateSimple(username: string, password: string): boolean {
  return username === "admin" && password === "P@ssword01";
}

export function getSimpleUser(): SimpleUser {
  return SIMPLE_USER;
}

export function isSimpleAuthEnabled(): boolean {
  // Force simple auth for production deployment
  return true;
}
EOF

# Update the simple auth context
sudo tee "$APP_DIR/client/src/lib/simple-auth-context.tsx" > /dev/null << 'EOF'
import { createContext, useContext, useEffect, useState } from 'react';
import { SimpleUser } from './simple-auth';

interface SimpleAuthContextType {
  user: SimpleUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (username: string, password: string) => Promise<boolean>;
  logout: () => void;
}

const SimpleAuthContext = createContext<SimpleAuthContextType | null>(null);

export function SimpleAuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<SimpleUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check for existing session
    const storedToken = localStorage.getItem('simple-auth-token');
    if (storedToken) {
      // Verify token with backend
      fetch('/api/auth/user', {
        headers: {
          'Authorization': `Bearer ${storedToken}`
        }
      })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error('Token invalid');
      })
      .then(userData => {
        setUser(userData);
      })
      .catch(() => {
        // Token is invalid, remove it
        localStorage.removeItem('simple-auth-token');
        localStorage.removeItem('simple-auth-user');
      });
    }
    setIsLoading(false);
  }, []);

  const login = async (username: string, password: string): Promise<boolean> => {
    try {
      const response = await fetch('/api/auth/simple-login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ username, password })
      });

      if (response.ok) {
        const data = await response.json();
        setUser(data.user);
        localStorage.setItem('simple-auth-token', data.token);
        localStorage.setItem('simple-auth-user', JSON.stringify(data.user));
        return true;
      }
    } catch (error) {
      console.error('Login failed:', error);
    }
    return false;
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('simple-auth-token');
    localStorage.removeItem('simple-auth-user');
  };

  return (
    <SimpleAuthContext.Provider value={{
      user,
      isAuthenticated: !!user,
      isLoading,
      login,
      logout,
    }}>
      {children}
    </SimpleAuthContext.Provider>
  );
}

export function useSimpleAuth() {
  const context = useContext(SimpleAuthContext);
  if (!context) {
    throw new Error('useSimpleAuth must be used within a SimpleAuthProvider');
  }
  return context;
}
EOF

# Update query client
sudo tee "$APP_DIR/client/src/lib/queryClient.ts" > /dev/null << 'EOF'
import { QueryClient, QueryFunction } from "@tanstack/react-query";

async function throwIfResNotOk(res: Response) {
  if (!res.ok) {
    const text = (await res.text()) || res.statusText;
    throw new Error(`${res.status}: ${text}`);
  }
}

function getAuthToken() {
  return localStorage.getItem('simple-auth-token');
}

export async function apiRequest(
  method: string,
  url: string,
  data?: unknown | undefined,
): Promise<Response> {
  const token = getAuthToken();
  const headers: Record<string, string> = {};
  
  if (data) {
    headers["Content-Type"] = "application/json";
  }
  
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const res = await fetch(url, {
    method,
    headers,
    body: data ? JSON.stringify(data) : undefined,
    credentials: "include",
  });

  await throwIfResNotOk(res);
  return res;
}

type UnauthorizedBehavior = "returnNull" | "throw";
export const getQueryFn: <T>(options: {
  on401: UnauthorizedBehavior;
}) => QueryFunction<T> =
  ({ on401: unauthorizedBehavior }) =>
  async ({ queryKey }) => {
    const token = getAuthToken();
    const headers: Record<string, string> = {};
    
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }

    const res = await fetch(queryKey.join("/") as string, {
      headers,
      credentials: "include",
    });

    if (unauthorizedBehavior === "returnNull" && res.status === 401) {
      return null;
    }

    await throwIfResNotOk(res);
    return await res.json();
  };

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      queryFn: getQueryFn({ on401: "throw" }),
      refetchInterval: false,
      refetchOnWindowFocus: false,
      staleTime: Infinity,
      retry: false,
    },
    mutations: {
      retry: false,
    },
  },
});
EOF

echo "2. Updating server routes..."
# Copy the updated server routes
sudo cp ../server/routes.ts "$APP_DIR/server/routes.ts"

echo "3. Setting permissions..."
sudo chown -R ubuntu:ubuntu "$APP_DIR"

echo "4. Restarting service..."
sudo systemctl restart canvas-course-generator.service

echo "5. Waiting for service to start..."
sleep 5

if sudo systemctl is-active --quiet canvas-course-generator.service; then
    echo "✅ Service restarted successfully!"
    echo "🎯 Visit https://shell.dpvils.org and login with admin/P@ssword01"
else
    echo "❌ Service failed to restart. Checking logs..."
    sudo journalctl -u canvas-course-generator.service -n 10 --no-pager
fi