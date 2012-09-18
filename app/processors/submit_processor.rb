# Copyright 2012 Twitter, Inc. and others.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Submits Tasks to MTurk
class SubmitProcessor < Job::ThreadPoolProcessor
  NAME = "Submitting Tasks"
  KILL_MESSAGE = <<-END
    Some tasks may have been submitted. To close these tasks, use the "Close
    Evaluation" button. To re-submit this evaluation, use the "retry" button.
    To re-submit this evaluation with changes, use the "Copy" button on the
    front page to copy this evaluation and submit the new evaluation.
  END

  def process task_id
    MTurkUtils.submit_task Task.find(task_id)
  end

  def before
    e = Evaluation.find(options['evaluation_id'])
    e.status = Evaluation::STATUS_ID[:submitted]
    e.save!
  end
end