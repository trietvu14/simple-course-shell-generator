import { createContext, useContext, useEffect, useState } from 'react';

export interface User {
  id: number;
  oktaId: string;
  email: string;
  firstName: string;
  lastName: string;
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  logout: () => void;
  refreshAuth: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const refreshAuth = async () => {
    // Temporary bypass for development - use test authentication
    try {
      const response = await fetch('/api/auth/test-login');
      if (response.ok) {
        const userData = await response.json();
        setUser(userData);
        setIsLoading(false);
        return;
      }
    } catch (error) {
      console.error('Test auth failed:', error);
    }

    // Original Okta authentication logic (commented out for now)
    // if (!authState?.isAuthenticated || !authState.idToken) {
    //   setUser(null);
    //   setIsLoading(false);
    //   localStorage.removeItem('okta-user');
    //   return;
    // }

    // try {
    //   // Get user info from Okta token
    //   const userInfo = await oktaAuth.getUser();
    //   
    //   // Store user info in localStorage for API calls
    //   localStorage.setItem('okta-user', JSON.stringify(userInfo));
    //   
    //   // Send user info to backend to create/update user record
    //   const response = await apiRequest('POST', '/api/auth/okta-callback', {
    //     oktaId: userInfo.sub,
    //     email: userInfo.email,
    //     firstName: userInfo.given_name,
    //     lastName: userInfo.family_name,
    //   });
    //   
    //   const userData = await response.json();
    //   setUser(userData);
    // } catch (error) {
    //   console.error('Auth refresh failed:', error);
    //   setUser(null);
    //   localStorage.removeItem('okta-user');
    // } finally {
    //   setIsLoading(false);
    // }
    
    setIsLoading(false);
  };

  useEffect(() => {
    refreshAuth();
  }, []);

  const handleLogout = async () => {
    try {
      setUser(null);
      localStorage.removeItem('okta-user');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  return (
    <AuthContext.Provider value={{
      user,
      isAuthenticated: !!user,
      isLoading,
      logout: handleLogout,
      refreshAuth,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}