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

class EvaluationRoutesTest < ActionController::TestCase
  test "root" do
    assert_recognizes({:controller => 'evaluations', :action => 'index'}, '/')
  end

  test "resource routing" do
    assert_resource_routed 'evaluations'
  end

  test "random task" do
    assert_routing({:method => 'get', :path => '/evaluations/10/random_task'},
                   {:controller => 'evaluations', :action => 'random_task', :id => "10"})
  end

  test "submit" do
    assert_routing({:method => 'post', :path => '/evaluations/10/submit'},
                   {:controller => 'evaluations', :action => 'submit', :id => "10"})
  end

  test "purge" do
    assert_routing({:method => 'post', :path => '/evaluations/10/purge'},
                   {:controller => 'evaluations', :action => 'purge', :id => "10"})
  end

  test "close" do
    assert_routing({:method => 'post', :path => '/evaluations/10/close'},
                   {:controller => 'evaluations', :action => 'close', :id => "10"})
  end

  test "approve_all" do
    assert_routing({:method => 'post', :path => '/evaluations/10/approve_all'},
                   {:controller => 'evaluations', :action => 'approve_all', :id => "10"})
  end

  test "edit_template" do
    assert_routing({:method => 'get', :path => '/evaluations/10/edit_template'},
                   {:controller => 'evaluations', :action => 'edit_template', :id => "10"})
  end

  test "update_template" do
    assert_routing({:method => 'put', :path => '/evaluations/10/update_template'},
                   {:controller => 'evaluations', :action => 'update_template', :id => "10"})
  end
end