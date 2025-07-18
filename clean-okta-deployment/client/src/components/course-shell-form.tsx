import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Trash2, Plus, Play } from "lucide-react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { createCourseShells } from "@/lib/canvas-api";
import { useToast } from "@/hooks/use-toast";

const courseShellSchema = z.object({
  name: z.string().min(1, "Course name is required"),
  courseCode: z.string().min(1, "Course code is required"),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
});

const formSchema = z.object({
  numberOfShells: z.number().min(1).max(50),
  shells: z.array(courseShellSchema),
});

type FormData = z.infer<typeof formSchema>;

interface CourseShellFormProps {
  selectedAccounts: string[];
  onProgressStart: (batchId: string) => void;
}

export default function CourseShellForm({ selectedAccounts, onProgressStart }: CourseShellFormProps) {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      numberOfShells: 2,
      shells: [
        { name: "", courseCode: "", startDate: "", endDate: "" },
        { name: "", courseCode: "", startDate: "", endDate: "" },
      ],
    },
  });

  const numberOfShells = form.watch("numberOfShells");
  const shells = form.watch("shells");

  const resetFormToDefault = () => {
    const defaultValues = {
      numberOfShells: 2,
      shells: [
        { name: "", courseCode: "", startDate: "", endDate: "" },
        { name: "", courseCode: "", startDate: "", endDate: "" },
      ],
    };
    form.reset(defaultValues);
  };

  const createMutation = useMutation({
    mutationFn: createCourseShells,
    onSuccess: (data) => {
      toast({
        title: "Course creation started",
        description: `Creating ${data.totalShells} course shells across ${selectedAccounts.length} accounts`,
      });
      onProgressStart(data.batchId);
      queryClient.invalidateQueries({ queryKey: ["/api/recent-activity"] });
      
      // Reset form to default state after successful submission
      resetFormToDefault();
      
      // Show success toast for form reset
      setTimeout(() => {
        toast({
          title: "Form reset",
          description: "Course shell configuration has been cleared and ready for new input",
        });
      }, 1000);
    },
    onError: (error) => {
      toast({
        title: "Error creating courses",
        description: error.message,
        variant: "destructive",
      });
    },
  });

  const updateShellCount = (count: number) => {
    const currentShells = form.getValues("shells");
    const newShells = [];
    
    for (let i = 0; i < count; i++) {
      if (currentShells[i]) {
        newShells.push(currentShells[i]);
      } else {
        newShells.push({ name: "", courseCode: "", startDate: "", endDate: "" });
      }
    }
    
    form.setValue("shells", newShells);
    form.setValue("numberOfShells", count);
  };

  const addShell = () => {
    const newCount = numberOfShells + 1;
    updateShellCount(newCount);
  };

  const removeShell = (index: number) => {
    const newShells = shells.filter((_, i) => i !== index);
    form.setValue("shells", newShells);
    form.setValue("numberOfShells", newShells.length);
  };

  const onSubmit = (data: FormData) => {
    if (selectedAccounts.length === 0) {
      toast({
        title: "No accounts selected",
        description: "Please select at least one account to create course shells",
        variant: "destructive",
      });
      return;
    }

    const shellsData = data.shells.map(shell => ({
      name: shell.name,
      courseCode: shell.courseCode,
      accountId: "", // Will be set for each account
      startDate: shell.startDate || undefined,
      endDate: shell.endDate || undefined,
    }));

    createMutation.mutate({
      shells: shellsData,
      selectedAccounts,
    });
  };

  const totalShells = numberOfShells * selectedAccounts.length;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg font-semibold text-neutral-800">Course Shell Configuration</CardTitle>
      </CardHeader>
      <CardContent>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            {/* Number of Shells */}
            <div>
              <Label className="text-sm font-medium text-neutral-700 mb-2 block">Number of Course Shells</Label>
              <div className="flex items-center space-x-4">
                <Input
                  type="number"
                  min="1"
                  max="50"
                  value={numberOfShells}
                  onChange={(e) => updateShellCount(parseInt(e.target.value) || 1)}
                  className="w-20"
                />
                <span className="text-sm text-neutral-600">shells per selected account</span>
              </div>
              <p className="text-xs text-neutral-500 mt-1">
                With {selectedAccounts.length} account{selectedAccounts.length !== 1 ? 's' : ''} selected, 
                this will create {totalShells} total course shells
              </p>
            </div>

            {/* Course Shell Details */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <Label className="text-sm font-medium text-neutral-700">Course Shell Details</Label>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={addShell}
                  className="text-canvas-blue hover:text-blue-700"
                >
                  <Plus className="mr-1" size={16} />
                  Add Shell
                </Button>
              </div>

              <div className="space-y-4">
                {shells.map((shell, index) => (
                  <div key={index} className="border border-neutral-200 rounded-lg p-4">
                    <div className="flex items-center justify-between mb-3">
                      <h4 className="text-sm font-medium text-neutral-800">
                        Shell {index + 1} of {numberOfShells}
                      </h4>
                      {numberOfShells > 1 && (
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => removeShell(index)}
                          className="text-neutral-400 hover:text-error"
                        >
                          <Trash2 size={16} />
                        </Button>
                      )}
                    </div>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <FormField
                        control={form.control}
                        name={`shells.${index}.name`}
                        render={({ field }) => (
                          <FormItem>
                            <FormLabel className="text-xs font-medium text-neutral-600">Course Name</FormLabel>
                            <FormControl>
                              <Input
                                placeholder="e.g., Introduction to Psychology"
                                {...field}
                                className="text-sm"
                              />
                            </FormControl>
                            <FormMessage />
                          </FormItem>
                        )}
                      />
                      <FormField
                        control={form.control}
                        name={`shells.${index}.courseCode`}
                        render={({ field }) => (
                          <FormItem>
                            <FormLabel className="text-xs font-medium text-neutral-600">Course Code</FormLabel>
                            <FormControl>
                              <Input
                                placeholder="e.g., PSYC-101"
                                {...field}
                                className="text-sm"
                              />
                            </FormControl>
                            <FormMessage />
                          </FormItem>
                        )}
                      />
                    </div>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                      <FormField
                        control={form.control}
                        name={`shells.${index}.startDate`}
                        render={({ field }) => (
                          <FormItem>
                            <FormLabel className="text-xs font-medium text-neutral-600">Start Date</FormLabel>
                            <FormControl>
                              <Input
                                type="date"
                                {...field}
                                className="text-sm"
                              />
                            </FormControl>
                            <FormMessage />
                          </FormItem>
                        )}
                      />
                      <FormField
                        control={form.control}
                        name={`shells.${index}.endDate`}
                        render={({ field }) => (
                          <FormItem>
                            <FormLabel className="text-xs font-medium text-neutral-600">End Date</FormLabel>
                            <FormControl>
                              <Input
                                type="date"
                                {...field}
                                className="text-sm"
                              />
                            </FormControl>
                            <FormMessage />
                          </FormItem>
                        )}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Summary */}
            <div className="bg-neutral-50 rounded-lg p-4">
              <h4 className="text-sm font-medium text-neutral-800 mb-3">Creation Summary</h4>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-neutral-600">Total Shells:</span>
                  <span className="font-semibold text-neutral-800 ml-2">{totalShells}</span>
                </div>
                <div>
                  <span className="text-neutral-600">Selected Accounts:</span>
                  <span className="font-semibold text-neutral-800 ml-2">{selectedAccounts.length}</span>
                </div>
                <div>
                  <span className="text-neutral-600">Shells per Account:</span>
                  <span className="font-semibold text-neutral-800 ml-2">{numberOfShells}</span>
                </div>
                <div>
                  <span className="text-neutral-600">Estimated Time:</span>
                  <span className="font-semibold text-neutral-800 ml-2">~{Math.ceil(totalShells / 10)} min</span>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex justify-end space-x-3">
              <Button
                type="button"
                variant="outline"
                onClick={resetFormToDefault}
                disabled={createMutation.isPending}
              >
                Reset Form
              </Button>
              <Button
                type="submit"
                disabled={createMutation.isPending || selectedAccounts.length === 0}
                className="bg-canvas-blue hover:bg-blue-700"
              >
                <Play className="mr-2" size={16} />
                {createMutation.isPending ? 'Creating...' : 'Create Course Shells'}
              </Button>
            </div>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
