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

class MTurkUsersControllerTest < ActionController::TestCase
  setup do
    login
  end

  # This asserts that a method that normally returns a JSON response requires
  # a privileged user.
  #
  # protected_method: This is the method that should get called on the
  #                   user when the block is executed by a privileged
  #                   user.
  # success_status:   If the block executes as a privileged user, it is expected
  #                   to render the JSON: {:status => <success_status>}
  # block:            This block should send a request to the controller that
  #                   calls protected_method iff the current user is privileged
  def assert_require_priv protected_method, success_status
    user = create :m_turk_user, :prod => true
    MTurkUser.stubs(:find).with(user.id.to_s).returns(user)

    # assert that an unprivileged user gets a Forbidden response
    login
    user.expects(protected_method).times(0)
    yield user
    assert_response 403
    assert_equal({'status' => 'Forbidden'}, json_response)

    # assert that a privileged user can do it
    login_priv
    user.expects(protected_method)
    yield user
    assert_response :success
    assert_equal({'status' => success_status}, json_response)
  end

  test "trust" do
    user = create :m_turk_user
    user.expects(:trust!)
    MTurkUser.expects(:find).with(user.id).returns(user)

    post :trust, :id => user.id
    assert_response :success
    assert_equal({'status' => 'Trusted'}, json_response)
  end

  test "trust requires privileges" do
    assert_require_priv :trust!, 'Trusted' do |user|
      post :trust, :id => user.id
    end
  end

  test "untrust" do
    user = create :m_turk_user
    user.expects(:untrust!)
    MTurkUser.expects(:find).with(user.id).returns(user)

    post :untrust, :id => user.id
    assert_response :success
    assert_equal({'status' => 'Untrusted'}, json_response)
  end

  test "untrust requires privileges" do
    assert_require_priv :untrust!, 'Untrusted' do |user|
      post :untrust, :id => user.id
    end
  end

  test "ban" do
    user = create :m_turk_user
    user.expects(:ban!)
    MTurkUser.expects(:find).with(user.id).returns(user)

    post :ban, :id => user.id
    assert_response :success
    assert_equal({'status' => 'Banned'}, json_response)
  end

  test "ban requires privileges" do
    assert_require_priv :ban!, 'Banned' do |user|
      post :ban, :id => user.id
    end
  end

  test "unban" do
    user = create :m_turk_user
    user.expects(:unban!)
    MTurkUser.expects(:find).with(user.id).returns(user)

    post :unban, :id => user.id
    assert_response :success
    assert_equal({'status' => 'Unbanned'}, json_response)
  end

  test "unban requires privileges" do
    assert_require_priv :unban!, 'Unbanned' do |user|
      post :unban, :id => user.id
    end
  end
end