#!/usr/bin/env ruby

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
    do_submit_to_production = submit_task_params.doSubmitToProduction

    task_type = task.humanEvalTaskType
    field_values_map = task.fieldValuesMap

    begin
      evaluation = Evaluation.find_by_name(task_type)
    rescue => e
      raise HumanEvalException.new("No evaluation exists with the given name")
    end

    task = evaluation.add_element(field_values_map)
    MTurkUtils.mturk(evaluation).submit_task(task)

    response = HumanEvalSubmitTaskResponse.new
    response.taskId = task.id
    response
  end

  # Gets the status of an existing Task, including completion status and answers, if available.
  # More details in human_eval.thrift.
  def fetchAnnotations(fetch_annotation_params)
    return nil if fetch_annotation_params.nil? or fetch_annotation_params.taskIdList.nil?

    task_id_results_map = fetch_annotation_params.taskIdList.inject({}) do |result, task_id|
      task_result = HumanEvalTaskResult.new
      begin
        task = Task.find(task_id)
        evaluation = Evaluation.find(task.evaluation_id)
        assignment = MTurkUtils.mturk(evaluation).getAssignmentsForHIT(evaluation.mturk_hit_type => task.mturk_hit)[:Assignment]
      rescue => e
        task_result.status = TaskStatus.INVALID
      end
      if task_result.status != TaskStatus.INVALID
        task_result.humanEvalTaskResultMap = assignment[:Answer]
        status = assignment[:AssignmentStatus]
        case status
        when 'Submitted'
          task_result.status = TaskStatus.PENDING
        when 'Approved'
          task_result.status = TaskStatus.COMPLETE
        when 'Rejected'
          task_result.status = TaskStatus.INVALID
        end
      end
      result[task_id] = task_result
      result
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
Rails.logger.info "Starting the Human Eval thrift server at #{Time.now}...\n"
handler.serve()
