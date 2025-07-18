import { useState } from 'react';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { toast } from "@/hooks/use-toast";
import { useSimpleAuth } from "@/lib/simple-auth-context";
import { LogIn } from "lucide-react";
import canvasLogo from "@assets/Canvas_logo_single_mark_1752601762771.png";

export default function SimpleLogin() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useSimpleAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const success = await login(username, password);
      if (success) {
        toast({
          title: "Login successful",
          description: "Welcome to Canvas Course Shell Generator",
        });
        window.location.replace('/dashboard');
      } else {
        toast({
          title: "Login failed",
          description: "Invalid username or password",
          variant: "destructive",
        });
      }
    } catch (error) {
      toast({
        title: "Login failed",
        description: "An error occurred during login",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

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
            Simple authentication for testing
          </CardDescription>
        </CardHeader>
        <CardContent>
          {/* Okta Login Option */}
          <div className="mb-6">
            <Button
              onClick={() => window.location.href = '/api/okta/login'}
              className="w-full bg-blue-600 hover:bg-blue-700"
              size="lg"
            >
              <LogIn className="mr-2 h-4 w-4" />
              Sign in with Okta
            </Button>
          </div>

          {/* Divider */}
          <div className="relative mb-6">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-white px-2 text-gray-500">Or use simple auth</span>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username">Username</Label>
              <Input
                id="username"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="admin"
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="DPVils25!"
                required
              />
            </div>
            <Button 
              type="submit" 
              className="w-full"
              disabled={isLoading}
              variant="outline"
            >
              {isLoading ? "Signing in..." : "Sign in with Simple Auth"}
            </Button>
          </form>
          <div className="mt-4 text-sm text-gray-600 text-center">
            <p>Test credentials:</p>
            <p>Username: admin</p>
            <p>Password: DPVils25!</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}