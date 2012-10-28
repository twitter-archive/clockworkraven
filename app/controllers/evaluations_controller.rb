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

require 'action_view/helpers/url_helper'

class EvaluationsController < ApplicationController
  before_filter :find_evaluation, :except => [:index, :new, :create]
  before_filter :require_priv, :only => [:destroy, :submit, :purge, :close, :approve_all]

  # Before launching a job to do something with an evaluation, make sure we
  # aren't already running a job for this evaluation
  before_filter :redirect_to_active_job, :only => [:submit, :close, :approve_all, :purge_from_mturk]

  private

  def find_evaluation
    @evaluation = Evaluation.find params[:id]
  end

  # If @evaluation is production, and the current user isn't privileged,
  # flash an error, redirect to @evaluation, and return false.
  def require_priv
    if @evaluation.prod? and !current_user.privileged?
      flash[:error] = STRINGS[:not_privileged]
      redirect_to evaluation_path(@evaluation)
      return false
    end

    return true
  end

  # If there is an active job running for this evaluation, redirect to it.
  def redirect_to_active_job
    if @evaluation.job and !@evaluation.job.ended?
      redirect_to job_path(@evaluation.job)
    end
  end

  # Creates a CSV (with header) of the original uploaded data file.
  def original_data_csv(sep = ',')
    CSV.generate(:col_sep => sep) do |csv|
      header = @evaluation.original_data_column_names
      csv << header

      @evaluation.tasks.each do |task|
        csv << header.map{ |col| task.data[col] }
      end
    end
  end

  public

  # GET /evaluations
  def index
    respond_to do |format|
      format.html # index.html.haml

      # JSON format returns table views to support server-side processing, as described in
      # http://railscasts.com/episodes/340-datatables?view=asciicast
      format.json do
        table = EvaluationsDatatable.new(view_context).as_json
        table[:aaData].each do |row|
          evaluation = row.pop
          row << view_context.link_to('Show', evaluation, :class => 'btn')
          row << view_context.link_to('Copy', new_evaluation_path(:based_on => evaluation.id), :class => 'btn btn-success')
          row << view_context.link_to('Remove', evaluation, :method => :delete, :class => 'btn btn-danger',
            :confirm => "Are you sure you want to remove this evaluation from Clockwork Raven? This does not close the evaluation or remove it from Mechanical Turk.")
        end
        render :json => "table"
      end
    end
  end

  # GET /evaluations/1
  def show
    respond_to do |format|
      format.html # show.html.haml
    end
  end

  # GET /evaluations/new
  def new
    if params[:based_on].blank?
      @evaluation = Evaluation.new

      if MTurkUser.where(:trusted => true).count == 0
        @evaluation.mturk_qualification = 'none'
      end
    else
      @evaluation = Evaluation.based_on(Evaluation.find(params[:based_on]))
    end

    respond_to do |format|
      format.html # new.html.haml
    end
  end

  # GET /evaluations/1/edit
  def edit
    # edit.html.haml
  end

  # POST /evaluations
  def create
    if params[:based_on]
      @evaluation = Evaluation.based_on(Evaluation.find(params[:based_on]))
      @evaluation.attributes = params[:evaluation]
    else
      @evaluation = Evaluation.new(params[:evaluation])
    end

    # parse data
    success = true
    data = nil
    if params[:evaluation][:data]
      begin
        data = InputParser.parse(params[:evaluation][:data])
      rescue InputParser::ParseError => e
        success = false
        flash[:error] = "Could not parse data: #{e.msg}"
      end
    end

    if success
      # create the eval
      Evaluation.transaction do
        @evaluation.user = current_user
        success = @evaluation.save

        if success and data
          @evaluation.add_tasks data
        end
      end
    end

    respond_to do |format|
      if success
        format.html { redirect_to edit_template_evaluation_url(@evaluation),
                      :notice => 'Evaluation was successfully created.' }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /evaluations/1
  def update
    @evaluation.attributes = params[:evaluation]

    # parse data
    data = nil
    success = true
    if params[:evaluation][:data]
      begin
        data = InputParser.parse(params[:evaluation][:data])
      rescue InputParser::ParseError => e
        success = false
        flash[:error] = "Could not parse data: #{e.msg}"
      end
    end

    # update the eval
    if success
      success = false
      @evaluation.transaction do
        if data
          # We are uploading a new dataset, so remove any existing tasks
          # before adding tasks from the new file.
          @evaluation.tasks.destroy_all
          @evaluation.add_tasks data
        end

        success = @evaluation.save
      end
    end

    respond_to do |format|
      if success
        format.html { redirect_to @evaluation, :notice => 'Evaluation was successfully updated.' }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /evaluations/1
  def destroy
    @evaluation.destroy

    respond_to do |format|
      format.html { redirect_to evaluations_url }
    end
  end

  def original_data
    @data = @evaluation.tasks.map{ |task| task.data }

    respond_to do |format|
      format.json {
        send_data @data,
                  :type => 'application/json',
                  :filename => 'original_data.json',
                  :disposition => 'attachment'
      }
      format.csv {
        send_data original_data_csv(','),
                  :type => 'text/csv',
                  :filename => 'original_data.csv',
                  :disposition => 'attachment'
      }
      format.tsv {
        send_data original_data_csv("\t"),
                  :type => 'text/tab-separated-values',
                  :filename => 'original_data.tsv',
                  :disposition => 'attachment'
      }
    end
  end

  # GET /evaluations/1/random_task
  def random_task
    @task = @evaluation.random_task

    render 'tasks/show', :layout => 'mturk'
  end

  # POST /evaluations/1/submit
  def submit
    job = @evaluation.submit!

    redirect_to job_url(job)
  end

  # POST /evaluations/1/purge
  def purge
    job = @evaluation.purge_from_mturk!

    redirect_to job_url(job)
  end

  # POST /evaluations/1/close
  def close
    job = @evaluation.close!

    redirect_to job_url(job)
  end

  # POST /evaluations/1/approve_all
  def approve_all
    job = @evaluation.approve_all!

    redirect_to job_url(job)
  end

  # GET /evaluations/1/edit_template
  def edit_template
    if @evaluation.tasks.size > 0
      @fields = @evaluation.tasks.first.data.keys
    else
      @fields = []
    end
  end

  # PUT /evaluations/1/update_template
  def update_template
    params[:evaluation] ||= {}

    if @evaluation.tasks.size > 0
      @fields = @evaluation.tasks.first.data.keys
    else
      @fields = []
    end

    # build template
    template = []

    # make a deep copy of params[:evaluation] to work on
    evaluation_params = Marshal.load(Marshal.dump(params[:evaluation]))

    # gather all types of sections
    {
      'headers_attributes' => :_header,
      'texts_attributes' => :_text,
      'components_attributes' => nil,
      'mc_questions_attributes' => :_mc,
      'fr_questions_attributes' => :_fr
    }.each do |param, type_id|
      template += (evaluation_params[param] || {}).values.map do |section|
        if section[:_destroy] == '1'
          nil
        else
          section[:type] ||= type_id

          # for components, we need to use the part of the data element that's
          # for that components
          unless section[:type].to_s[0] == '_'
            section[:data] = section[:data][section[:type]]
          end

          if type_id == :_fr or type_id == :_mc
            # for fr and mc questions, filter out irrelevant items
            section.delete_if{|k, v| k.to_s != 'type' and k.to_s != 'order'}
          end

          section
        end
      end.compact.reject{ |section| section[:type].blank? }
      #   ^ remove sections that have been marked for deletion or are unselected templates
    end

    # sort
    template.sort_by! {|section| section[:order].to_i}

    # update questions
    success = @evaluation.update_attributes({
      :template => template,
      :mc_questions_attributes => params[:evaluation][:mc_questions_attributes],
      :fr_questions_attributes => params[:evaluation][:fr_questions_attributes],
      :metadata                => params[:evaluation][:metadata]
    }.delete_if{|k, v| v.nil?});

    respond_to do |format|
      if success
        format.html { redirect_to @evaluation, :notice => 'Evaluation was successfully updated.' }
      else
        format.html { render :action => "edit_template" }
      end
    end
  end
end
