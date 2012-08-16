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

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :require_login, :except => [:login, :persist_login]
  before_filter :add_x_frame_options_header

  def current_user
    return @current_user if @current_user

    # we only load the user from a session cookie if we're using the same
    # database we were using when the cookie was issued
    if session[:db_sig] == DatabaseSignature.generate
      @current_user = User.find_by_id(session[:user_id])
    end

    return @current_user
  end

  private

  def add_x_frame_options_header
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
  end

  def require_login
    if current_user.nil?
      flash[:notice] = STRINGS[:not_logged_in]
      session[:return_to] = request.path
      redirect_to login_url
    end
  end
end
