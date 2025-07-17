import { useState, useEffect } from "react";
import { useMutation } from "@tanstack/react-query";
import Header from "@/components/header";
import AccountSelection from "@/components/account-selection";
import CourseShellForm from "@/components/course-shell-form";
import ProgressModal from "@/components/progress-modal";
import RecentActivity from "@/components/recent-activity";
import CanvasConnection from "@/components/canvas-connection";

import { useAuth } from "@/lib/auth-context";
import { useSimpleAuth } from "@/lib/simple-auth-context";
import { isSimpleAuthEnabled } from "@/lib/simple-auth";
import { useToast } from "@/hooks/use-toast";

export default function Dashboard() {
  const [selectedAccounts, setSelectedAccounts] = useState<string[]>([]);
  const [progressBatchId, setProgressBatchId] = useState<string | null>(null);
  const { toast } = useToast();
  const { user } = isSimpleAuthEnabled() ? useSimpleAuth() : useAuth();

  const handleProgressStart = (batchId: string) => {
    setProgressBatchId(batchId);
  };

  const handleProgressClose = () => {
    setProgressBatchId(null);
  };



  return (
    <div className="min-h-screen bg-neutral-100">
      <Header />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Page Header */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-neutral-800 mb-2">Create Course Shells</h2>
          <p className="text-neutral-600">Generate course shells across your Canvas accounts and subaccounts</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column - Account Selection & Canvas Connection */}
          <div className="lg:col-span-1 space-y-6">
            {/* Canvas Connection */}
            <CanvasConnection />
            
            {/* Account Selection */}
            <AccountSelection
              selectedAccounts={selectedAccounts}
              onAccountsChange={setSelectedAccounts}
            />
          </div>

          {/* Course Shell Form */}
          <div className="lg:col-span-2">
            <CourseShellForm
              selectedAccounts={selectedAccounts}
              onProgressStart={handleProgressStart}
            />
          </div>
        </div>

        {/* Recent Activity */}
        <div className="mt-8">
          <RecentActivity />
        </div>
      </div>

      {/* Progress Modal */}
      <ProgressModal
        batchId={progressBatchId}
        onClose={handleProgressClose}
      />
    </div>
  );
}
