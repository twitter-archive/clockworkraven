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

# Closes Tasks and imports results
class CloseProcessor < Job::ThreadPoolProcessor
  NAME = "Closing Tasks"
  KILL_MESSAGE = <<-END
    Some tasks may have been closed, some may still be open. To finish closing
    tasks, use the "Close Evaluation" button again.
  END

  def process task_id
    task = Task.find task_id
    # destroy any old responses left over from previous runs
    if task.task_response
      task.task_response.destroy
    end

    MTurkUtils.force_expire task
    MTurkUtils.fetch_results task
  end

  # we do a bunch of processing in #after, so double the effective number
  # of tasks so we can increment the counter in #after
  def before
    @total *= 2
  end

  # add metadata as questions
  def after
    @items.each do |task_id|
      Task.find(task_id).add_metadata_as_questions
      increment_completion
    end

    e = Evaluation.find(options['evaluation_id'])
    e.status = Evaluation::STATUS_ID[:closed]
    e.save!
  end
end