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

class TaskResponsesRoutesTest < ActionController::TestCase
  test "resource routing" do
    assert_nested_resource_routed 'task_responses', 'evaluations'
  end

  test "approve" do
    assert_routing({:method => 'post', :path => '/evaluations/10/task_responses/20/approve'},
                   {:controller => 'task_responses', :action => 'approve', :id => '20', :evaluation_id => '10'})
  end

  test "reject" do
    assert_routing({:method => 'post', :path => '/evaluations/10/task_responses/20/reject'},
                   {:controller => 'task_responses', :action => 'reject', :id => '20', :evaluation_id => '10'})
  end
end