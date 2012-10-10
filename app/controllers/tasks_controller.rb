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

class TasksController < ApplicationController
  # GET /evaluations/1/tasks/1
  def show
    @task = Task.find(params[:id])
    @mturk = true
    render 'mturk', :layout => 'mturk'
  end

  # GET /evaluations/1/tasks/1/complete
  def complete
    @task = Task.find(params[:id])
    @mturk = false
    render 'internal'
  end

  # POST /evaluations/1/tasks/1/complete
  def submit
    evaluation = Evaluation.find params[:evaluation_id]
    @task = Task.find params[:id]

    @response = @task.build_task_response
    @response.source = 'internal'
    @response.m_turk_user = MTurkUser.find_or_create_by_id_and_prod(current_user.username, false)
    @response.work_duration = Time.now.to_i - params[:start_time].to_i

    params[:evaluation][:mc_q].each do |q_id, a_id|
      begin
        option = MCQuestionOption.find a_id.to_i
      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn("[fetch_results] Could not find MCQuestion #{answer_content}")
        next
      end

      question_response = @response.mc_question_responses.build
      question_response.mc_question_option = option
    end

    params[:evaluation][:fr_q].each do |q_id, resp|
      begin
        question = FRQuestion.find q_id.to_i
      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn("[fetch_results] Could not find FRQuestion #{question_id}")
        next
      end

      question_response = @response.fr_question_responses.build

      if resp.blank?
        resp = "No response given"
      end

      question_response.response = resp
      question_response.fr_question = question
    end

    if @response.save
      MTurkUtils.force_expire @task
      @task.add_metadata_as_questions
      task = evaluation.random_uncompleted_task
      if task
        redirect_to complete_evaluation_task_url(evaluation, task)
      else
        redirect_to evaluation_url(evaluation)
      end
    else
      render 'internal'
    end
  end

  # Renders the given task (as in #show), returning a string of the rendering
  def show_string task
    @task = task
    render_to_string :action => "mturk", :layout => 'mturk'
  end
end
