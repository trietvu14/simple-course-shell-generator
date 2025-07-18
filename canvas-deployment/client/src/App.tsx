import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Security } from '@okta/okta-react';
import { oktaAuth } from './lib/okta-config';
import { AuthProvider, useAuth } from "@/lib/auth-context";
import { SimpleAuthProvider, useSimpleAuth } from "@/lib/simple-auth-context";
import { isSimpleAuthEnabled } from "./lib/simple-auth";
import Dashboard from "@/pages/dashboard";
import Login from "@/pages/login";
import SimpleLogin from "@/pages/simple-login";
import Callback from "@/pages/callback";
import NotFound from "@/pages/not-found";
import TestAuth from "@/components/test-auth";

function ProtectedRoute({ component: Component }: { component: React.ComponentType }) {
  if (isSimpleAuthEnabled()) {
    const { isAuthenticated, isLoading } = useSimpleAuth();
    
    if (isLoading) {
      return (
        <div className="min-h-screen flex items-center justify-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      );
    }
    
    if (!isAuthenticated) {
      return <SimpleLogin />;
    }
    
    return <Component />;
  } else {
    const { isAuthenticated, isLoading } = useAuth();
    
    if (isLoading) {
      return (
        <div className="min-h-screen flex items-center justify-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      );
    }
    
    if (!isAuthenticated) {
      return <Login />;
    }
    
    return <Component />;
  }
}

function Router() {
  return (
    <Switch>
      <Route path="/" component={() => <ProtectedRoute component={Dashboard} />} />
      <Route path="/dashboard" component={() => <ProtectedRoute component={Dashboard} />} />
      <Route path="/test" component={TestAuth} />
      <Route path="/login" component={isSimpleAuthEnabled() ? SimpleLogin : Login} />
      <Route path="/callback" component={Callback} />
      <Route component={NotFound} />
    </Switch>
  );
}

function App() {
  if (isSimpleAuthEnabled()) {
    return (
      <QueryClientProvider client={queryClient}>
        <SimpleAuthProvider>
          <TooltipProvider>
            <Toaster />
            <Router />
          </TooltipProvider>
        </SimpleAuthProvider>
      </QueryClientProvider>
    );
  } else {
    return (
      <QueryClientProvider client={queryClient}>
        <Security 
          oktaAuth={oktaAuth}
          restoreOriginalUri={async (oktaAuth, originalUri) => {
            window.location.replace(originalUri || '/dashboard');
          }}
        >
          <AuthProvider>
            <TooltipProvider>
              <Toaster />
              <Router />
            </TooltipProvider>
          </AuthProvider>
        </Security>
      </QueryClientProvider>
    );
  }
}

export default App;
