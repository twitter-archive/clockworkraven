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
  before_filter :find_user
  before_filter :require_priv


  private

  def find_user
    @user = MTurkUser.find(params[:id])
  end

  def require_priv
    if @user.prod? and !current_user.privileged?
      render :json => {:status => "Forbidden"}, :status => 403
    end
  end

  public

  # POST /users/1/trust
  def trust
    @user.trust!
    @user.task_responses.each do |resp|
      expire_action(:controller => 'task_responses',
                    :action => 'index',
                    :evaluation_id => resp.task.evaluation)
    end
    render :json => {:status => "Trusted"}
  end

  # POST /users/1/untrust
  def untrust
    @user.untrust!
    @user.task_responses.each do |resp|
      expire_action(:controller => 'task_responses',
                    :action => 'index',
                    :evaluation_id => resp.task.evaluation)
    end
    render :json => {:status => "Untrusted"}
  end

  # POST /users/1/ban
  def ban
    @user.ban!
    @user.task_responses.each do |resp|
      expire_action(:controller => 'task_responses',
                    :action => 'index',
                    :evaluation_id => resp.task.evaluation)
    end
    render :json => {:status => "Banned"}
  end

  # POST /users/1/unban
  def unban
    @user.unban!
    @user.task_responses.each do |resp|
      expire_action(:controller => 'task_responses',
                    :action => 'index',
                    :evaluation_id => resp.task.evaluation)
    end
    render :json => {:status => "Unbanned"}
  end
end
