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

class MTurkUserRoutesTest < ActionController::TestCase
  test "resource routing" do
    assert_resource_routed 'm_turk_users'
  end

  test "trust" do
    assert_routing({:method => 'post', :path => '/m_turk_users/20/trust'},
                   {:controller => 'm_turk_users', :action => 'trust', :id => '20'})
  end

  test "untrust" do
    assert_routing({:method => 'post', :path => '/m_turk_users/20/untrust'},
                   {:controller => 'm_turk_users', :action => 'untrust', :id => '20'})
  end

  test "ban" do
    assert_routing({:method => 'post', :path => '/m_turk_users/20/ban'},
                   {:controller => 'm_turk_users', :action => 'ban', :id => '20'})
  end

  test "unban" do
    assert_routing({:method => 'post', :path => '/m_turk_users/20/unban'},
                   {:controller => 'm_turk_users', :action => 'unban', :id => '20'})
  end
end