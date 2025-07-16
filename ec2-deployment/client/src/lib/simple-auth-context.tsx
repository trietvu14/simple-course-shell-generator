import { createContext, useContext, useEffect, useState } from 'react';
import { SimpleUser, getSimpleUser } from './simple-auth';

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
    const storedUser = localStorage.getItem('simple-auth-user');
    if (storedUser) {
      setUser(JSON.parse(storedUser));
    }
    setIsLoading(false);
  }, []);

  const login = async (username: string, password: string): Promise<boolean> => {
    if (username === "admin" && password === "P@ssword01") {
      const simpleUser = getSimpleUser();
      setUser(simpleUser);
      localStorage.setItem('simple-auth-user', JSON.stringify(simpleUser));
      return true;
    }
    return false;
  };

  const logout = () => {
    setUser(null);
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