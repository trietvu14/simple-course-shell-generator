import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { SimpleAuthProvider, useSimpleAuth } from "@/lib/simple-auth-context";
import Dashboard from "@/pages/dashboard";
import SimpleLogin from "@/pages/simple-login";
import NotFound from "@/pages/not-found";

function ProtectedRoute({ component: Component }: { component: React.ComponentType }) {
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
}

function Router() {
  return (
    <Switch>
      <Route path="/" component={() => <ProtectedRoute component={Dashboard} />} />
      <Route path="/dashboard" component={() => <ProtectedRoute component={Dashboard} />} />
      <Route path="/login" component={SimpleLogin} />
      <Route component={NotFound} />
    </Switch>
  );
}

function App() {
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
}

export default App;