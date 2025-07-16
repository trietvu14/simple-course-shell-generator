import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { useAuth } from "@/lib/auth-context";
import { LogOut, BookOpen } from "lucide-react";

export default function Header() {
  const { user, logout } = useAuth();

  if (!user) {
    return null;
  }

  const initials = `${user.firstName.charAt(0)}${user.lastName.charAt(0)}`;

  return (
    <header className="bg-white shadow-sm border-b border-neutral-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center">
            <div className="flex-shrink-0 flex items-center">
              <div className="bg-orange-600 rounded-lg p-1.5 mr-3">
                <BookOpen className="h-5 w-5 text-white" />
              </div>
              <h1 className="text-xl font-semibold text-neutral-800">Canvas Course Shell Generator</h1>
            </div>
          </div>
          <div className="flex items-center space-x-4">
            <span className="text-sm text-neutral-600">Authenticated</span>
            <div className="flex items-center space-x-2">
              <Avatar className="w-8 h-8">
                <AvatarFallback className="bg-canvas-blue text-white text-sm font-medium">
                  {initials}
                </AvatarFallback>
              </Avatar>
              <span className="text-sm font-medium text-neutral-800">
                {user.firstName} {user.lastName}
              </span>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={logout}
              className="text-neutral-600 hover:text-neutral-800"
            >
              <LogOut size={16} />
            </Button>
          </div>
        </div>
      </div>
    </header>
  );
}
