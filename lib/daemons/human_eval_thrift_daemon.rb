#!/usr/bin/env ruby

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

require File.dirname(__FILE__) + "/../../config/application"
Rails.application.require_environment!

require 'thrift'
require 'human_eval_task_manager'

class HumanEvalTaskManagerHandler

  # Initializes Thrift connection state.
  def initialize
    @processor = HumanEvalTaskManager::Processor.new(self)
    @transport = Thrift::ServerSocket.new(9090)
    @transport_factory = Thrift::BufferedTransportFactory.new()
    @server = Thrift::SimpleServer.new(@processor, @transport, @transport_factory)
  end

  # Submits a Task to MTurk given Task questions; returns the Clockwork Raven Task ID of the newly
  # created Task. More details in human_eval.thrift.
  def submitTask(submit_task_params)
    return nil if submit_task_params.nil?
    task = submit_task_params.task
    field_values_map = task.fieldValuesMap

    # Evaluations are identified by their names, which are currently unique
    evaluation = Evaluation.find_by_name(task.humanEvalTaskType)
    raise HumanEvalException.new("No Evaluation exists with the given name: #{task.humanEvalTaskType}") if evaluation.nil?

    new_task_to_submit = evaluation.add_task(field_values_map)
    MTurkUtils.submit_task(new_task_to_submit) if evaluation.prod? and submit_task_params.doSubmitToProduction

    response = HumanEvalSubmitTaskResponse.new
    response.taskId = new_task_to_submit.id
    response
  end

  # Gets the status of an existing Task, including completion status and answers, if available.
  # More details in human_eval.thrift.
  def fetchAnnotations(fetch_annotation_params)
    return nil if fetch_annotation_params.nil? or fetch_annotation_params.taskIdList.nil?

    task_id_results_map = fetch_annotation_params.taskIdList.each_with_object({}) do |task_id, result|
      task_result = HumanEvalTaskResult.new

      task = Task.find_by_id(task_id)
      raise HumanEvalException.new("No Task exists with the given Task ID: #{task_id}") if task.nil?

      assignment = MTurkUtils.fetch_assignment_for_task(task)
      if assignment.nil?
        task_result.status = TaskStatus::PENDING
      else
        task_result.humanEvalTaskResultMap = MTurkUtils.assignment_results_to_hash(assignment)
        task_result.status = case assignment[:AssignmentStatus]
          when 'Submitted'
            TaskStatus::PENDING
          when 'Approved'
            TaskStatus::COMPLETE
          when 'Rejected'
            TaskStatus::INVALID
        end
      end

      result[task_id] = task_result
    end

    response = HumanEvalFetchAnnotationResponse.new
    response.taskIdResultsMap = task_id_results_map
    response
  end

  # Starts Thrift server.
  def serve
    @server.serve()
  end

end

handler = HumanEvalTaskManagerHandler.new()
Rails.logger.info "Starting the Human Eval thrift server daemon at #{Time.now}...\n"
handler.serve()
