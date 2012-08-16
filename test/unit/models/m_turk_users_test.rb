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

class MTurkUsersTest < ActiveSupport::TestCase
  test "trusting a user in prod" do
    user = create :m_turk_user, :trusted => 0, :prod => 1

    prod = mturk_prod_mock
    prod.expects(:assignQualification).
         with(:QualificationTypeId => MTURK_CONFIG[:qualifications][:trusted][:prod],
              :WorkerId => user.id)

    user.trust!

    assert user.trusted?
  end

  test "trusting a user in sandbox" do
    user = create :m_turk_user, :trusted => 0, :prod => 0

    sb = mturk_sandbox_mock
    sb.expects(:assignQualification).
       with(:QualificationTypeId => MTURK_CONFIG[:qualifications][:trusted][:sandbox],
            :WorkerId => user.id)

    user.trust!

    assert user.trusted?
  end

  test "untrusting a user in prod" do
    user = create :m_turk_user, :trusted => 1, :prod => 1

    prod = mturk_prod_mock
    prod.expects(:revokeQualification).
         with(:QualificationTypeId => MTURK_CONFIG[:qualifications][:trusted][:prod],
              :SubjectId => user.id)

    user.untrust!

    assert !user.trusted?
  end

  test "untrusting a user in sandbox" do
    user = create :m_turk_user, :trusted => 1, :prod => 0

    sb = mturk_sandbox_mock
    sb.expects(:revokeQualification).
       with(:QualificationTypeId => MTURK_CONFIG[:qualifications][:trusted][:sandbox],
            :SubjectId => user.id)

    user.untrust!

    assert !user.trusted?
  end

  test "banning a user" do
    user = create :m_turk_user, :banned => 0, :prod => 0

    sb = mturk_sandbox_mock
    sb.expects(:blockWorker).with do |params|
      (params[:WorkerId] == user.id) and !params[:Reason].empty?
    end

    user.ban!

    assert user.banned?
  end

  test "unbanning a user" do
    user = create :m_turk_user, :banned => 1, :prod => 0

    sb = mturk_sandbox_mock
    sb.expects(:unblockWorker).with(:WorkerId => user.id)

    user.unban!

    assert !user.banned?
  end
end