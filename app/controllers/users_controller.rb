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

class UsersController < ApplicationController
  # Updating an account is only allowed with the password auth system.
  before_filter :require_password_auth, :except => [:show, :reset_key]

  private

  def require_password_auth
    unless AUTH_CONFIG[:type] == :password
      flash[:error] = STRINGS[:password_auth_required]
      redirect_to account_path
    end
  end

  public

  # GET /account
  def show
    # show.html.haml
  end

  # GET /account/edit
  def edit
    # edit.html.haml
  end

  # PUT /account
  def update
    current_user.name  = params[:user][:name]  unless params[:user][:name].nil?
    current_user.email = params[:user][:email] unless params[:user][:email].nil?

    unless params[:user][:password].blank?
      current_user.password = params[:user][:password]
      current_user.password_confirmation = (params[:user][:password_confirmation] || '')
    end

    respond_to do |format|
      if current_user.save
        format.html { redirect_to account_path, :notice => 'Account was successfully updated.' }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # POST /account/reset_key
  def reset_key
    current_user.generate_key

    respond_to do |format|
      if current_user.save
        format.html { redirect_to account_path, :notice => 'Your API key has been reset.' }
      else
        format.html { redirect_to account_path, :error => 'Could not reset API key.' }
      end
    end
  end
end
