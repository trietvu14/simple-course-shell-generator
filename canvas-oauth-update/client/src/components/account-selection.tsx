import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Search, RefreshCw, University, Folder, FolderOpen, X } from "lucide-react";
import { getCanvasAccounts, type CanvasAccount } from "@/lib/canvas-api";

type HierarchicalAccount = CanvasAccount & { depth?: number };

interface AccountSelectionProps {
  selectedAccounts: string[];
  onAccountsChange: (accounts: string[]) => void;
}

export default function AccountSelection({ selectedAccounts, onAccountsChange }: AccountSelectionProps) {
  const [searchTerm, setSearchTerm] = useState("");

  const { data: accounts = [], isLoading, refetch } = useQuery({
    queryKey: ["/api/accounts"],
    queryFn: getCanvasAccounts,
  });

  const filteredAccounts = accounts.filter(account =>
    account.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const buildAccountHierarchy = (accounts: CanvasAccount[]): HierarchicalAccount[] => {
    const accountMap = new Map<string, CanvasAccount>();
    accounts.forEach(acc => accountMap.set(acc.id, acc));
    
    const rootAccounts = accounts.filter(acc => !acc.parent_account_id);
    const result: CanvasAccount[] = [];
    
    const addAccountWithChildren = (account: CanvasAccount, depth: number = 0) => {
      // Add current account with depth info
      result.push({ ...account, depth });
      
      // Find and add children recursively
      const children = accounts.filter(child => child.parent_account_id === account.id);
      children.forEach(child => {
        addAccountWithChildren(child, depth + 1);
      });
    };
    
    rootAccounts.forEach(root => {
      addAccountWithChildren(root, 0);
    });
    
    return result;
  };

  const hierarchicalAccounts = buildAccountHierarchy(filteredAccounts);

  const handleAccountToggle = (accountId: string) => {
    const newSelected = selectedAccounts.includes(accountId)
      ? selectedAccounts.filter(id => id !== accountId)
      : [...selectedAccounts, accountId];
    onAccountsChange(newSelected);
  };

  const removeAccount = (accountId: string) => {
    onAccountsChange(selectedAccounts.filter(id => id !== accountId));
  };

  const getAccountIcon = (account: HierarchicalAccount) => {
    const depth = account.depth || 0;
    if (depth === 0) {
      return <University className="text-canvas-blue" size={16} />;
    } else if (depth === 1) {
      return <FolderOpen className="text-amber-600" size={16} />;
    } else {
      return <Folder className="text-neutral-500" size={16} />;
    }
  };

  const getSelectedAccountNames = () => {
    return accounts
      .filter(acc => selectedAccounts.includes(acc.id))
      .map(acc => ({ id: acc.id, name: acc.name }));
  };

  return (
    <Card className="h-fit">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg font-semibold text-neutral-800">Account Selection</CardTitle>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => refetch()}
            disabled={isLoading}
            className="text-canvas-blue hover:text-blue-700"
          >
            <RefreshCw className={`mr-1 ${isLoading ? 'animate-spin' : ''}`} size={16} />
            Refresh
          </Button>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-neutral-400" size={16} />
          <Input
            type="text"
            placeholder="Search accounts..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>

        {/* Account Tree */}
        <ScrollArea className="h-96">
          <div className="space-y-2">
            {hierarchicalAccounts.map((account) => {
              const isSelected = selectedAccounts.includes(account.id);
              const depth = account.depth || 0;
              const isRoot = depth === 0;
              
              return (
                <div
                  key={account.id}
                  className={`flex items-center space-x-2 p-2 hover:bg-neutral-50 rounded-lg cursor-pointer`}
                  style={{ marginLeft: `${depth * 20}px` }}
                  onClick={() => handleAccountToggle(account.id)}
                >
                  <Checkbox
                    id={account.id}
                    checked={isSelected}
                    onCheckedChange={() => handleAccountToggle(account.id)}
                  />
                  {getAccountIcon(account)}
                  <label
                    htmlFor={account.id}
                    className={`text-sm cursor-pointer ${
                      isRoot ? 'font-medium text-neutral-800' : 'text-neutral-600'
                    }`}
                  >
                    {account.name}
                  </label>
                  {depth > 0 && (
                    <Badge variant="outline" className="ml-2 text-xs">
                      Level {depth}
                    </Badge>
                  )}
                </div>
              );
            })}
          </div>
        </ScrollArea>

        {/* Selected Accounts Summary */}
        {selectedAccounts.length > 0 && (
          <div className="p-3 bg-canvas-light rounded-lg">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-canvas-blue">Selected Accounts:</span>
              <Badge variant="secondary" className="text-canvas-blue font-semibold">
                {selectedAccounts.length}
              </Badge>
            </div>
            <div className="space-y-1">
              {getSelectedAccountNames().map((account) => (
                <div key={account.id} className="flex items-center justify-between text-xs text-neutral-600">
                  <span>{account.name}</span>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => removeAccount(account.id)}
                    className="h-4 w-4 p-0 text-neutral-400 hover:text-error"
                  >
                    <X size={12} />
                  </Button>
                </div>
              ))}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
