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

class AuthFlowTest < ActionDispatch::IntegrationTest
  setup do
    # mock out LDAP with some test users
    mock_ldap do
      user 'testuser', 'foopass'
      user 'joeuser', 'barpass'
      user 'noaccess', 'coolpass', :access => false
    end
  end

  test "Login and browse site" do
    # create 2 sessions, to check interleaving of requests
    testuser = open_session
    joeuser = open_session
    joeuser = open_session

    # request protected pages
    testuser.get_via_redirect jobs_path
    joeuser.get_via_redirect new_evaluation_path

    assert_equal login_path, testuser.path
    assert_equal STRINGS[:not_logged_in], testuser.flash[:notice]

    assert_equal login_path, joeuser.path
    assert_equal STRINGS[:not_logged_in], testuser.flash[:notice]

    # failed login, then successful login
    testuser.post_via_redirect login_path, :username => 'noaccess', :password => 'coolpass'
    assert_equal login_path, testuser.path
    assert_equal STRINGS[:invalid_login], testuser.flash[:error]

    joeuser.post_via_redirect login_path, :username => 'joeuser', :password => 'barpass'
    assert_equal new_evaluation_path, joeuser.path
    assert_equal "#{STRINGS[:logged_in_prefix]} joeuser", joeuser.flash[:notice]

    testuser.post_via_redirect login_path, :username => 'testuser', :password => 'foopass'
    assert_equal jobs_path, testuser.path
    assert_equal "#{STRINGS[:logged_in_prefix]} testuser", testuser.flash[:notice]

    # joeuser now logs out and in, to make sure that return_to doesn't carry over
    joeuser.post_via_redirect logout_path
    assert_equal login_path, joeuser.path
    assert_equal STRINGS[:logged_out], joeuser.flash[:notice]

    joeuser.post_via_redirect login_path, :username => 'joeuser', :password => 'barpass'
    assert_equal root_path, joeuser.path
    assert_equal "#{STRINGS[:logged_in_prefix]} joeuser", joeuser.flash[:notice]
  end
end