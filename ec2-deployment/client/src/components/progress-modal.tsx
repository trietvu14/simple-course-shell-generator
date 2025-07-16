import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { CheckCircle, Clock, Loader2, AlertCircle } from "lucide-react";
import { getBatchStatus, type BatchStatus } from "@/lib/canvas-api";

interface ProgressModalProps {
  batchId: string | null;
  onClose: () => void;
}

export default function ProgressModal({ batchId, onClose }: ProgressModalProps) {
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    setIsOpen(!!batchId);
  }, [batchId]);

  const { data: batchStatus, isLoading } = useQuery({
    queryKey: ["/api/batches", batchId, "status"],
    queryFn: () => getBatchStatus(batchId!),
    enabled: !!batchId,
    refetchInterval: batchId ? 2000 : false, // Poll every 2 seconds
  });

  const handleClose = () => {
    setIsOpen(false);
    onClose();
  };

  if (!batchId || isLoading) {
    return null;
  }

  const batch = batchStatus?.batch;
  const shells = batchStatus?.shells || [];
  
  if (!batch) {
    return null;
  }

  const progressPercentage = (batch.completedShells / batch.totalShells) * 100;
  const isComplete = batch.status === 'completed';

  const getShellIcon = (status: string) => {
    switch (status) {
      case 'created':
        return <CheckCircle className="text-success" size={16} />;
      case 'failed':
        return <AlertCircle className="text-error" size={16} />;
      case 'pending':
        return <Loader2 className="text-canvas-blue animate-spin" size={16} />;
      default:
        return <Clock className="text-neutral-400" size={16} />;
    }
  };

  const getStatusDescription = (shell: any) => {
    switch (shell.status) {
      case 'created':
        return `Created successfully`;
      case 'failed':
        return `Failed: ${shell.error || 'Unknown error'}`;
      case 'pending':
        return `Creating...`;
      default:
        return `Waiting...`;
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <DialogTitle className="text-lg font-semibold text-neutral-800">
              Creating Course Shells
            </DialogTitle>
            <div className="flex items-center space-x-2">
              <div className={`w-4 h-4 rounded-full ${isComplete ? 'bg-success' : 'bg-canvas-blue animate-pulse'}`} />
              <span className="text-sm text-neutral-600">
                {isComplete ? 'Complete' : 'In Progress'}
              </span>
            </div>
          </div>
        </DialogHeader>
        
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-sm text-neutral-600">Overall Progress</span>
            <span className="text-sm font-medium text-neutral-800">
              {batch.completedShells + batch.failedShells} of {batch.totalShells} shells
            </span>
          </div>
          
          <Progress value={progressPercentage} className="w-full" />
          
          {batch.failedShells > 0 && (
            <div className="flex items-center space-x-2">
              <Badge variant="destructive" className="text-xs">
                {batch.failedShells} failed
              </Badge>
              <Badge variant="secondary" className="text-xs">
                {batch.completedShells} succeeded
              </Badge>
            </div>
          )}
          
          <ScrollArea className="h-48">
            <div className="space-y-3">
              {shells.map((shell, index) => (
                <div key={shell.id} className="flex items-center space-x-3">
                  {getShellIcon(shell.status)}
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-neutral-800 truncate">{shell.name}</p>
                    <p className="text-xs text-neutral-500 truncate">
                      {getStatusDescription(shell)}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </ScrollArea>
        </div>
      </DialogContent>
    </Dialog>
  );
}
