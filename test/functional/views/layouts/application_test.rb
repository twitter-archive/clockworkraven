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

require 'test_helper'

# Tests for the application layout. We need to make requests for a number
# of controllers to test the behavior in different parts of the site.
module ApplicationLayoutTest
  class LoggedOutTest < ActionController::TestCase
    tests LoginsController

    test "No username shown when logged out" do
      get :login
      assert_select_none '#current_user'
    end

    test "Error flash shown" do
      get :login, {}, {}, {:error => 'some error msg'}
      assert response.body.include? 'some error msg'
    end

    test "Info flash shown" do
      get :login, {}, {}, {:notice => 'some info msg'}
      assert response.body.include? 'some info msg'
    end
  end

  class LoggedInEvaluationsTest < ActionController::TestCase
    tests EvaluationsController

    test "Username shown when logged in" do
      login
      get :index
      assert_select '#current_user'
    end

    test "Evaluations link active when in evaluations section" do
      login
      get :index
      assert_select 'li#evaluations_link.active'
      assert_select_none 'li#jobs_link.active'
    end
  end

  class LoggedInJobsTest < ActionController::TestCase
    tests JobsController

    test "Jobs link active when in jobs section" do
      login
      get :index
      assert_select 'li#jobs_link.active'
      assert_select_none 'li#evaluations_link.active'
    end
  end
end