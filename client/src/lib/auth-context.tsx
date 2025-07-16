import { createContext, useContext, useEffect, useState } from 'react';
import { useOktaAuth } from '@okta/okta-react';
import { apiRequest } from './queryClient';

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
  const { oktaAuth, authState } = useOktaAuth();
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const refreshAuth = async () => {
    if (!authState?.isAuthenticated || !authState.idToken) {
      setUser(null);
      setIsLoading(false);
      localStorage.removeItem('okta-user');
      return;
    }

    try {
      // Get user info from Okta token
      const userInfo = await oktaAuth.getUser();
      
      // Store user info in localStorage for API calls
      localStorage.setItem('okta-user', JSON.stringify(userInfo));
      
      // Send user info to backend to create/update user record
      const response = await apiRequest('POST', '/api/auth/okta-callback', {
        oktaId: userInfo.sub,
        email: userInfo.email,
        firstName: userInfo.given_name,
        lastName: userInfo.family_name,
      });
      
      const userData = await response.json();
      setUser(userData);
    } catch (error) {
      console.error('Auth refresh failed:', error);
      setUser(null);
      localStorage.removeItem('okta-user');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (authState?.isAuthenticated !== undefined) {
      refreshAuth();
    }
  }, [authState?.isAuthenticated]);

  const handleLogout = async () => {
    try {
      await oktaAuth.signOut();
      setUser(null);
      localStorage.removeItem('okta-user');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  return (
    <AuthContext.Provider value={{
      user,
      isAuthenticated: !!user && !!authState?.isAuthenticated,
      isLoading: isLoading || !authState,
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