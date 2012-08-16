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

class UsersControllerTest < ActionController::TestCase
  setup do
    login
  end

  test "show" do
    get :show
    assert_response :success
  end

  test "edit" do
    with_consts :AUTH_CONFIG => {:type => :password} do
      get :edit
      assert_response :success
    end
  end

  test "edit requires password auth" do
    with_consts :AUTH_CONFIG => {:type => :ldap} do
      get :edit
      assert_redirected_to account_path
      assert_equal STRINGS[:password_auth_required], flash[:error]
    end
  end

  test "update requires password auth" do
    with_consts :AUTH_CONFIG => {:type => :ldap} do
      get :update, :user => {:email => 'new_email@foo.com'}
      assert_redirected_to account_path
      assert_equal STRINGS[:password_auth_required], flash[:error]
      assert_not_equal 'new_email@foo.com', @controller.current_user.reload.email
    end
  end

  # asserts that trying to update with the given attributes fails validations
  def assert_validations_fail attrs
    put :update, :user => attrs
    assert_response :success
    assert @controller.current_user.errors.any?, "Validation expected to fail"
  end

  test "update" do
    with_consts :AUTH_CONFIG => {:type => :password} do
      # basic update
      put :update, :user => {:email                 => 'new_email@foo.com',
                             :name                  => 'new name',
                             :password              => 'newpass',
                             :password_confirmation => 'newpass'}

      assert_redirected_to account_path

      assert_equal 'Account was successfully updated.', flash[:notice]
      assert_equal 'new_email@foo.com', @controller.current_user.email
      assert_equal 'new name',          @controller.current_user.name

      assert_equal @controller.current_user.password, 'newpass'

      # try to update protected attributes
      username = @controller.current_user.username
      digest   = @controller.current_user.password_digest

      put :update, :user => {:email           => 'second_email@foo.com',
                             :password_digest => 'new_digest',
                             :username        => 'new_username',
                             :privileged      => true}

      assert_redirected_to account_path

      assert_equal 'Account was successfully updated.', flash[:notice]
      assert_equal 'second_email@foo.com', @controller.current_user.email
      assert_equal username,               @controller.current_user.username
      assert_equal digest.to_s,            @controller.current_user.password_digest.to_s
      assert_equal false,                  @controller.current_user.privileged

      # not updating password
      put :update, :user => {:email => 'third_email@foo.com'}
      assert_redirected_to account_path
      assert_equal @controller.current_user.password, 'newpass'

      # failed validations
      assert_validations_fail :name     => ' '
      assert_validations_fail :email    => 'foo'
      assert_validations_fail :password => '1', :password_confirmation => '2'
      assert_validations_fail :password => '1', :password_confirmation => ''
    end
  end
end