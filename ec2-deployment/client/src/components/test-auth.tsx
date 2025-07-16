import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';

export default function TestAuth() {
  const [isTestUser, setIsTestUser] = useState(false);
  const queryClient = useQueryClient();

  const { data: testUser, isLoading: isCreatingTestUser, error: testUserError } = useQuery({
    queryKey: ['/api/auth/test-login'],
    enabled: isTestUser,
    retry: false,
  });

  const { data: canvasTest, isLoading: isTestingCanvas, error: canvasError } = useQuery({
    queryKey: ['/api/test/canvas'],
    enabled: isTestUser && !!testUser,
    retry: false,
  });

  const { data: accounts, isLoading: isLoadingAccounts, error: accountsError } = useQuery({
    queryKey: ['/api/accounts'],
    enabled: isTestUser && !!testUser,
    retry: false,
  });

  const handleTestLogin = async () => {
    setIsTestUser(true);
  };

  const handleReset = () => {
    setIsTestUser(false);
    queryClient.clear();
  };

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle>Test Authentication & Canvas API</CardTitle>
        <CardDescription>
          Bypass Okta authentication for testing course shell functions
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {!isTestUser ? (
          <div className="text-center">
            <Button onClick={handleTestLogin} size="lg">
              Create Test User & Test Canvas API
            </Button>
            <p className="text-sm text-muted-foreground mt-2">
              This will create a temporary user and test the Canvas API connection
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="font-semibold">Test Results</h3>
              <Button onClick={handleReset} variant="outline" size="sm">
                Reset Test
              </Button>
            </div>

            {/* Test User Creation */}
            <div className="space-y-2">
              <h4 className="font-medium">1. Test User Creation</h4>
              {isCreatingTestUser ? (
                <Alert>
                  <AlertDescription>Creating test user...</AlertDescription>
                </Alert>
              ) : testUserError ? (
                <Alert variant="destructive">
                  <AlertDescription>Error: {testUserError.message}</AlertDescription>
                </Alert>
              ) : testUser ? (
                <Alert>
                  <AlertDescription>
                    ✅ Test user created: {testUser.firstName} {testUser.lastName} ({testUser.email})
                  </AlertDescription>
                </Alert>
              ) : null}
            </div>

            {/* Canvas API Test */}
            <div className="space-y-2">
              <h4 className="font-medium">2. Canvas API Connection</h4>
              {isTestingCanvas ? (
                <Alert>
                  <AlertDescription>Testing Canvas API...</AlertDescription>
                </Alert>
              ) : canvasError ? (
                <Alert variant="destructive">
                  <AlertDescription>Canvas API Error: {canvasError.message}</AlertDescription>
                </Alert>
              ) : canvasTest ? (
                <Alert>
                  <AlertDescription>
                    ✅ Canvas API working: Connected to {canvasTest.rootAccount?.name || 'Canvas'}
                  </AlertDescription>
                </Alert>
              ) : null}
            </div>

            {/* Accounts Loading */}
            <div className="space-y-2">
              <h4 className="font-medium">3. Canvas Accounts Loading</h4>
              {isLoadingAccounts ? (
                <Alert>
                  <AlertDescription>Loading Canvas accounts...</AlertDescription>
                </Alert>
              ) : accountsError ? (
                <Alert variant="destructive">
                  <AlertDescription>Accounts Error: {accountsError.message}</AlertDescription>
                </Alert>
              ) : accounts ? (
                <Alert>
                  <AlertDescription>
                    ✅ Loaded {accounts.length} Canvas accounts
                  </AlertDescription>
                </Alert>
              ) : null}
            </div>

            {/* Account List */}
            {accounts && accounts.length > 0 && (
              <div className="space-y-2">
                <h4 className="font-medium">Available Canvas Accounts</h4>
                <div className="max-h-40 overflow-y-auto border rounded p-2">
                  {accounts.map((account: any) => (
                    <div key={account.id} className="text-sm py-1">
                      <strong>{account.name}</strong> (ID: {account.id})
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Success Message */}
            {testUser && canvasTest && accounts && (
              <Alert>
                <AlertDescription>
                  🎉 All tests passed! You can now use the course shell generator without Okta authentication.
                </AlertDescription>
              </Alert>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}