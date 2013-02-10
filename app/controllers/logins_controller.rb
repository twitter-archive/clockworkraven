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

class LoginsController < ApplicationController
  # GET /login
  def login
    if current_user
      redirect_to root_path
    end
  end

  # POST /login
  def persist_login
    user = User.auth params[:username], params[:password]

    if user.nil?
      flash[:error] = STRINGS[:invalid_login]
      redirect_to login_url
    else
      session[:user_id] = user.id
      session[:db_sig] = DatabaseSignature.generate
      flash[:notice] = (STRINGS[:logged_in_prefix] + " #{user.username}")

      # Clear return_to so it doesn't get re-used if the user logs out and logs
      # in again.
      target = (session[:return_to] || root_path)
      session.delete :return_to
      redirect_to target
    end
  end

  # POST /logout
  def logout
    session.delete(:user_id)
    flash[:notice] = STRINGS[:logged_out]
    redirect_to login_url
  end
end
