exception HumanEvalException {
  1: string description
}

enum TaskStatus {
  INVALID = 1;
  PENDING = 2;
  COMPLETE = 3;
}

// Structure to represent human eval task information.
struct HumanEvalTask {
  // Type of task to be run.
  // This is the name field of the Evaluation and is used as a unique identifier.
  1: required string humanEvalTaskType;
  // Each human eval task type is associated with an MTurk template. This is a
  // map of fields to their values to be used when filling the task template.
  2: required map<string, string> fieldValuesMap;
}

// Structure to represent human eval task result information.
struct HumanEvalTaskResult {
  1: optional map<string, string> humanEvalTaskResultMap;
  2: required TaskStatus status;
}

// Structure to represent params to submitTask.
struct HumanEvalSubmitTaskParams {
  1: required HumanEvalTask task;

  // Flag to suggest if task is for production or dry-run.
  // In case of dry-run, the task is validated by checking if
  // fieldValuesMap is valid for the associated humanEvalTaskType.
  2: required bool doSubmitToProduction;
}

// Structure to represent response from submitTask.
struct HumanEvalSubmitTaskResponse {
  // Task id provided by human eval manager.
  1: required i64 taskId;
}

// Structure to represent params to fetch annotations.
struct HumanEvalFetchAnnotationParams {
  1: required set<i64> taskIdSet;
}

// Structure to represent reponse from fetch annotations.
struct HumanEvalFetchAnnotationResponse {
  1: required map<i64, HumanEvalTaskResult> taskIdResultsMap;
}

service HumanEvalTaskManager {
   // Submit a task to human eval.
   HumanEvalSubmitTaskResponse submitTask(1: HumanEvalSubmitTaskParams params)
       throws (1: HumanEvalException hec)

   // Fetches result for a list of human eval tasks.
   HumanEvalFetchAnnotationResponse fetchAnnotations(1: HumanEvalFetchAnnotationParams params)
       throws (1: HumanEvalException hec)
}

