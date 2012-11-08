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

class MTurkUsersController < ApplicationController
  before_filter :find_user, :except => [:index]
  before_filter :require_priv, :except => [:index]

  private

  def find_user
    @m_turk_user = MTurkUser.find(params[:id])
  end

  def require_priv
    if @m_turk_user.prod? and !current_user.privileged?
      render :json => {:status => "Forbidden"}, :status => 403
    end
  end

  public

  # GET /m_turk_users
  def index
    @m_turk_users = MTurkUser.order('id DESC')

    respond_to do |format|
      format.html # index.html.haml
    end
  end

  # GET /m_turk_users/1
  def show
    respond_to do |format|
      format.html # show.html.haml
    end
  end

  # PUT /m_turk_users/1
  def update
    if params[:m_turk_user][:name] != @m_turk_user
      @m_turk_user.evaluations.each do |e|
        expire_action(:controller => 'task_responses',
                      :action => 'index',
                      :evaluation_id => e.id)
      end
    end

    respond_to do |format|
      if @m_turk_user.update_attributes(params[:m_turk_user])
        format.html { redirect_to @m_turk_user, :notice => 'Worker was successfully updated.' }
      else
        format.html { render :action => "show" }
      end
    end
  end

  # POST /m_turk_users/1/trust
  def trust
    @m_turk_user.trust!
    @m_turk_user.task_responses.each do |resp|
      expire_action(:controller => 'task_responses',
                    :action => 'index',
                    :evaluation_id => resp.task.evaluation)
    end
    render :json => {:status => "Trusted"}
  end

  # POST /m_turk_users/1/untrust
  def untrust
    @m_turk_user.untrust!
    @m_turk_user.task_responses.each do |resp|
      expire_action(:controller => 'task_responses',
                    :action => 'index',
                    :evaluation_id => resp.task.evaluation)
    end
    render :json => {:status => "Untrusted"}
  end

  # POST /m_turk_users/1/ban
  def ban
    @m_turk_user.ban!
    @m_turk_user.task_responses.each do |resp|
      expire_action(:controller => 'task_responses',
                    :action => 'index',
                    :evaluation_id => resp.task.evaluation)
    end
    render :json => {:status => "Banned"}
  end

  # POST /m_turk_users/1/unban
  def unban
    @m_turk_user.unban!
    @m_turk_user.task_responses.each do |resp|
      expire_action(:controller => 'task_responses',
                    :action => 'index',
                    :evaluation_id => resp.task.evaluation)
    end
    render :json => {:status => "Unbanned"}
  end
end
