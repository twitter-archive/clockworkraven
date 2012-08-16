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

class UserRoutesTest < ActionController::TestCase
  test "show account" do
    assert_routing({:method => 'get', :path => '/account'},
                   {:controller => 'users', :action => 'show'})
  end

  test "edit account" do
    assert_routing({:method => 'get', :path => '/account/edit'},
                   {:controller => 'users', :action => 'edit'})
  end

  test "update account" do
    assert_routing({:method => 'put', :path => '/account'},
                   {:controller => 'users', :action => 'update'})
  end
end