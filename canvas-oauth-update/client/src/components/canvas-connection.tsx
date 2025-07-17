import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ExternalLink, RefreshCw, CheckCircle2, AlertCircle, Link as LinkIcon } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { useAuth } from "@/lib/auth-context";
import { useSimpleAuth } from "@/lib/simple-auth-context";
import { isSimpleAuthEnabled } from "@/lib/simple-auth";

interface CanvasTokenStatus {
  hasToken: boolean;
  expiresAt?: string;
  scope?: string;
  isExpired?: boolean;
  timeUntilExpiry?: string;
}

export default function CanvasConnection() {
  const { toast } = useToast();
  const { user } = isSimpleAuthEnabled() ? useSimpleAuth() : useAuth();
  const [isConnecting, setIsConnecting] = useState(false);

  // Query Canvas token status
  const { data: tokenStatus, isLoading, error } = useQuery<CanvasTokenStatus>({
    queryKey: ["/api/canvas/oauth/status"],
    enabled: !!user,
    refetchInterval: 60000, // Check every minute
  });

  // Mutation to revoke Canvas token
  const revokeMutation = useMutation({
    mutationFn: async () => {
      await apiRequest("/api/canvas/oauth/revoke", {
        method: "DELETE",
      });
    },
    onSuccess: () => {
      toast({
        title: "Canvas Disconnected",
        description: "Canvas access has been revoked successfully.",
      });
      queryClient.invalidateQueries({ queryKey: ["/api/canvas/oauth/status"] });
      queryClient.invalidateQueries({ queryKey: ["/api/accounts"] });
    },
    onError: (error) => {
      toast({
        title: "Error",
        description: "Failed to revoke Canvas access. Please try again.",
        variant: "destructive",
      });
    },
  });

  const handleConnectCanvas = () => {
    setIsConnecting(true);
    // Redirect to Canvas OAuth authorization
    window.location.href = "/api/canvas/oauth/authorize";
  };

  const handleDisconnectCanvas = () => {
    revokeMutation.mutate();
  };

  const formatTimeUntilExpiry = (expiresAt: string): string => {
    const now = new Date();
    const expiry = new Date(expiresAt);
    const diff = expiry.getTime() - now.getTime();
    
    if (diff <= 0) return "Expired";
    
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    } else {
      return `${minutes}m`;
    }
  };

  const isTokenExpired = (tokenStatus: CanvasTokenStatus): boolean => {
    if (!tokenStatus.expiresAt) return false;
    return new Date(tokenStatus.expiresAt) <= new Date();
  };

  const getStatusBadge = () => {
    if (isLoading) {
      return <Badge variant="outline">Checking...</Badge>;
    }
    
    if (error || !tokenStatus) {
      return <Badge variant="destructive">Error</Badge>;
    }
    
    if (!tokenStatus.hasToken) {
      return <Badge variant="outline">Not Connected</Badge>;
    }
    
    if (isTokenExpired(tokenStatus)) {
      return <Badge variant="destructive">Expired</Badge>;
    }
    
    return <Badge variant="default" className="bg-green-600">Connected</Badge>;
  };

  const getStatusIcon = () => {
    if (isLoading) {
      return <RefreshCw className="h-4 w-4 animate-spin" />;
    }
    
    if (error || !tokenStatus || !tokenStatus.hasToken || isTokenExpired(tokenStatus)) {
      return <AlertCircle className="h-4 w-4 text-red-500" />;
    }
    
    return <CheckCircle2 className="h-4 w-4 text-green-500" />;
  };

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <LinkIcon className="h-5 w-5" />
          Canvas Connection
          {getStatusBadge()}
        </CardTitle>
        <CardDescription>
          Connect your Canvas account to access course management features
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-center gap-2">
          {getStatusIcon()}
          <span className="text-sm text-muted-foreground">
            {isLoading ? (
              "Checking connection status..."
            ) : error ? (
              "Error checking connection"
            ) : !tokenStatus?.hasToken ? (
              "Canvas not connected"
            ) : isTokenExpired(tokenStatus) ? (
              "Canvas access expired"
            ) : (
              `Connected • Expires in ${formatTimeUntilExpiry(tokenStatus.expiresAt!)}`
            )}
          </span>
        </div>

        {tokenStatus && tokenStatus.hasToken && tokenStatus.scope && (
          <div className="text-xs text-muted-foreground">
            <strong>Permissions:</strong> {tokenStatus.scope}
          </div>
        )}

        <div className="flex gap-2">
          {!tokenStatus?.hasToken || isTokenExpired(tokenStatus) ? (
            <Button
              onClick={handleConnectCanvas}
              disabled={isConnecting}
              className="flex items-center gap-2"
            >
              {isConnecting ? (
                <RefreshCw className="h-4 w-4 animate-spin" />
              ) : (
                <ExternalLink className="h-4 w-4" />
              )}
              Connect Canvas
            </Button>
          ) : (
            <Button
              onClick={handleDisconnectCanvas}
              variant="outline"
              disabled={revokeMutation.isPending}
              className="flex items-center gap-2"
            >
              {revokeMutation.isPending ? (
                <RefreshCw className="h-4 w-4 animate-spin" />
              ) : (
                <AlertCircle className="h-4 w-4" />
              )}
              Disconnect Canvas
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}