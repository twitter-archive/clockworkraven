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

module LoginTestHelper
  # logs in as a test user
  def login
    @user = create :user
    session[:user_id] = @user.id
    session[:db_sig] = DatabaseSignature.generate
    @controller.instance_variable_set :@current_user, nil
  end

  # logs in as a test user who is privileged
  def login_priv
    @user = create :user, :privileged => true
    session[:user_id] = @user.id
    session[:db_sig] = DatabaseSignature.generate
    @controller.instance_variable_set :@current_user, nil
  end

  # logs out
  def logout
    session.delete(:user)
  end
end