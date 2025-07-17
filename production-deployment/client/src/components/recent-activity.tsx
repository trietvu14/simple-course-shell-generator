import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { CheckCircle, AlertTriangle, Clock } from "lucide-react";
import { getRecentActivity, type CreationBatch } from "@/lib/canvas-api";
import { formatDistanceToNow } from "date-fns";

export default function RecentActivity() {
  const { data: batches = [], isLoading } = useQuery({
    queryKey: ["/api/recent-activity"],
    queryFn: getRecentActivity,
  });

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-lg font-semibold text-neutral-800">Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="flex items-center space-x-4 p-3 bg-neutral-50 rounded-lg animate-pulse">
                <div className="w-10 h-10 bg-neutral-200 rounded-full" />
                <div className="flex-1 space-y-2">
                  <div className="h-4 bg-neutral-200 rounded w-3/4" />
                  <div className="h-3 bg-neutral-200 rounded w-1/2" />
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  if (batches.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-lg font-semibold text-neutral-800">Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8">
            <Clock className="mx-auto h-12 w-12 text-neutral-400 mb-4" />
            <p className="text-sm text-neutral-600">No recent activity</p>
            <p className="text-xs text-neutral-500 mt-1">
              Your course creation history will appear here
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const getStatusIcon = (batch: CreationBatch) => {
    if (batch.status === 'completed' && batch.failedShells === 0) {
      return <CheckCircle className="text-success" size={20} />;
    } else if (batch.failedShells > 0) {
      return <AlertTriangle className="text-warning" size={20} />;
    } else {
      return <Clock className="text-neutral-400" size={20} />;
    }
  };

  const getStatusColor = (batch: CreationBatch) => {
    if (batch.status === 'completed' && batch.failedShells === 0) {
      return 'bg-success';
    } else if (batch.failedShells > 0) {
      return 'bg-warning';
    } else {
      return 'bg-neutral-400';
    }
  };

  const getStatusText = (batch: CreationBatch) => {
    if (batch.status === 'completed' && batch.failedShells === 0) {
      return `Successfully created ${batch.completedShells} course shells`;
    } else if (batch.failedShells > 0) {
      return `Partial success: ${batch.completedShells} of ${batch.totalShells} shells created`;
    } else {
      return `Creating ${batch.totalShells} course shells`;
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg font-semibold text-neutral-800">Recent Activity</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {batches.map((batch) => (
            <div key={batch.id} className="flex items-center space-x-4 p-3 bg-neutral-50 rounded-lg">
              <div className={`w-10 h-10 ${getStatusColor(batch)} rounded-full flex items-center justify-center`}>
                {getStatusIcon(batch)}
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium text-neutral-800">
                  {getStatusText(batch)}
                </p>
                <div className="flex items-center space-x-2 mt-1">
                  <p className="text-xs text-neutral-500">
                    {formatDistanceToNow(new Date(batch.createdAt), { addSuffix: true })}
                  </p>
                  <Badge variant="outline" className="text-xs">
                    Batch ID: {batch.batchId.slice(-8)}
                  </Badge>
                </div>
              </div>
              <Button
                variant="ghost"
                size="sm"
                className="text-canvas-blue hover:text-blue-700"
              >
                View Details
              </Button>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
