import { useOktaAuth } from '@okta/okta-react';
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { toast } from "@/hooks/use-toast";
import canvasLogo from "@assets/Canvas_logo_single_mark_1752601762771.png";

export default function Login() {
  const { oktaAuth, authState } = useOktaAuth();

  const handleLogin = async () => {
    try {
      await oktaAuth.signInWithRedirect();
    } catch (error) {
      toast({
        title: "Login failed",
        description: "Unable to redirect to login. Please try again.",
        variant: "destructive",
      });
    }
  };

  if (authState?.isAuthenticated) {
    window.location.replace('/dashboard');
    return null;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-4">
            <img 
              src={canvasLogo} 
              alt="Canvas Logo" 
              className="h-16 w-auto"
            />
          </div>
          <CardTitle>Canvas Course Shell Generator</CardTitle>
          <CardDescription>
            Please sign in with your Digital Promise account to continue
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={handleLogin} 
            className="w-full"
            disabled={authState?.isPending}
          >
            {authState?.isPending ? "Redirecting..." : "Sign in with Okta"}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}