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

# test that other controllers redirect
class NonLoginsControllerTest < ActionController::TestCase
  tests EvaluationsController

  setup do
    @user = create :user
    session.clear
  end

  test "no credentials" do
    assert_forbidden
  end

  test "bad user id" do
    if User.last
      session[:user_id] = User.last.id + 1
    else
      session[:user_id] = 999999
    end

    session[:db_sig] = DatabaseSignature.generate
    assert_forbidden
  end

  test "bad db sig" do
    user = create :user
    session[:user_id] = user.id
    session[:db_sig] = 'wrong'
    assert_forbidden
  end

  test "no db sig" do
    user = create :user
    session[:user_id] = user.id
    assert_forbidden
  end

  test "no id" do
    user = create :user
    session[:db_sig] = DatabaseSignature.generate
    assert_forbidden
  end

  test "valid user id" do
    user = create :user
    session[:db_sig] = DatabaseSignature.generate
    session[:user_id] = user.id

    get :index
    assert_response :success
  end

  test "invalid api key" do
    user = create :user
    get :index, :api_key => 'wrong'
    assert_forbidden
  end

  test "valid api key" do
    user = create :user
    get :index, :api_key => user.key

    get :index
    assert_response :success
  end

  # asserts that the user is redirected to the login screen when trying to
  # load a page
  def assert_forbidden
    get :index

    assert_redirected_to login_path
    assert_equal evaluations_path, session[:return_to]
    assert_equal STRINGS[:not_logged_in], flash[:notice]
    assert_nil @controller.current_user
  end
end

class LoginsControllerTest < ActionController::TestCase
  setup do
    # reset the session
    logout
    session.delete :return_to

    # mock out LDAP with some test users
    mock_ldap do
      group 'priv1', :priv => true do
        user 'joeuser', 'barpass'
      end
      group 'priv2', :priv => true do
        user 'testuser', 'foopass'
      end
      group 'othergroup' do
        user 'unpriv', 'coolpass'
      end
      group 'thirdgroup', :access => false do
        user 'noaccess', 'nicepass'
      end
    end
  end

  test "login when logged out" do
    get :login
    assert_response :success
  end

  test "login when logged in" do
    login
    get :login
    assert_redirected_to root_path
  end

  test "persist_login, correct auth, no return_to" do
    # test that multiple users can log in
    post :persist_login, :username => 'testuser', :password => 'foopass'
    assert_redirected_to root_path
    assert_equal 'testuser', User.find(session[:user_id]).username
    assert_equal "#{STRINGS[:logged_in_prefix]} testuser", flash[:notice]
    assert_privileged

    post :persist_login, :username => 'joeuser', :password => 'barpass'
    assert_redirected_to root_path
    assert_equal 'joeuser', User.find(session[:user_id]).username
    assert_equal "#{STRINGS[:logged_in_prefix]} joeuser", flash[:notice]
    assert_privileged
  end

  test "persist_login, correct auth, return_to" do
    # test that users are redirected back to session[:return_to]
    session[:return_to] = '/foo'
    post :persist_login, :username => 'testuser', :password => 'foopass'
    assert_redirected_to '/foo'
    assert_equal 'testuser', User.find(session[:user_id]).username
    assert_equal nil, session[:return_to]

    # test that if the user logs in again, they get redirected back to /,
    # not the previous return_to
    post :persist_login, :username => 'testuser', :password => 'foopass'
    assert_redirected_to root_path
    assert_equal 'testuser', User.find(session[:user_id]).username
  end

  test "persist_login, no username" do
    post :persist_login
    assert_login_failed
  end

  test "persist_login, nonexistant username" do
    post :persist_login, :username => 'nope', :password => 'nope'
    assert_login_failed
  end

  test "persist_login, no password" do
    post :persist_login, :username => 'testuser'
    assert_login_failed
  end

  test "persist_login, wrong password" do
    post :persist_login, :username => 'testuser', :password => 'wrong'
    assert_login_failed
  end

  test "persist_login, not in the group" do
    post :persist_login, :username => 'unpriv', :password => 'coolpass'
    assert_equal 'unpriv', User.find(session[:user_id]).username
    assert_equal "#{STRINGS[:logged_in_prefix]} unpriv", flash[:notice]
    assert_unprivileged
  end

  test "persist_login, no access" do
    post :persist_login, :username => 'noaccess', :password => 'nicepass'
    assert_login_failed
  end

  test "persist_login, invalid login, return_to" do
    # we check that if a return to is set and the user has an unsuccessful
    # login attempt followed by a successful one, we redirect after the
    # successful attempt
    session[:return_to] = '/foo'
    post :persist_login, :username => 'testuser', :password => 'wrongpass'
    assert_login_failed
    post :persist_login, :username => 'testuser', :password => 'foopass'
    assert_redirected_to '/foo'
    assert_equal 'testuser', User.find(session[:user_id]).username
    assert_privileged
  end

  test "log out" do
    login

    post :logout

    assert_redirected_to login_url
    assert_equal nil, session[:user]
    assert_equal STRINGS[:logged_out], flash[:notice]
  end

  private

  def assert_privileged
    assert User.find(session[:user_id]).privileged, "Expected curent user to be privileged"
  end

  def assert_unprivileged
    assert !User.find(session[:user_id]).privileged, "Expected current user to be unprivileged"
  end

  def assert_login_failed
    # not redirected, session[:user] remains
    #assert_redirected_to login_url
    assert_equal nil, session[:user]
    assert_equal STRINGS[:invalid_login], flash[:error]
  end
end