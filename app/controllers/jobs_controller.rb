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

class JobsController < ApplicationController
  # GET /evaluations
  def index
    @jobs = Job.page(params[:page]).order('id DESC')

    respond_to do |format|
      format.html # index.html.haml
    end
  end

  # GET /jobs/1
  # GET /jobs/1.json
  def show
    @job = Job.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json {
        render :json    => @job,
               :methods => [:status_name, :percentage, :total, :completed, :error, :ended?]
      }
    end
  end

  # POST /jobs/1/kill
  # POST /jobs/1/kill.json
  def kill
    @job = Job.find params[:id]
    @job.kill!

    respond_to do |format|
      format.html { redirect_to job_path(@job) }
      format.json {
        render :json    => @job,
               :methods => [:status_name, :percentage, :total, :completed, :error, :ended?]
      }
    end
  end
end