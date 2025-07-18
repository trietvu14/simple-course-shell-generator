import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { LogIn } from "lucide-react";

export function OktaLogin() {
  const handleOktaLogin = () => {
    // Redirect to Okta login
    window.location.href = '/api/okta/login';
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold">Canvas Course Shell Generator</CardTitle>
          <CardDescription>
            Sign in with your Digital Promise account to continue
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Button 
            onClick={handleOktaLogin}
            className="w-full"
            size="lg"
          >
            <LogIn className="mr-2 h-4 w-4" />
            Sign in with Okta
          </Button>
          
          <div className="text-center">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Use your Digital Promise credentials to access the Canvas Course Shell Generator
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}