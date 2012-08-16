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

class TaskResponsesTest < ActiveSupport::TestCase
  test "approving responses" do
    # create an eval with some questions and 3 tasks
    eval = create :evaluation

    task1 = create :task, :mturk_hit => 'hit_1', :evaluation => eval
    task2 = create :task, :mturk_hit => 'hit_2', :evaluation => eval

    response1 = create :task_response, :task => task1
    response2 = create :task_response, :task => task2

    sb = mturk_sandbox_mock

    # create a stub to provide a reasonable response for GetAssignmentForHITAll
    sb.stubs(:getAssignmentsForHITAll).
       with(:HITId => 'hit_1').
       returns([{
         :AssignmentId => 'a_1',
         :AssignmentStatus => 'Submitted'
       }, {
         :AssignmentId => 'a_2',
         :AssignmentStatus => 'Approved'
       }, {
         :AssignmentId => 'a_4',
         :AssignmentStatus => 'Submitted'
       }])

    sb.stubs(:getAssignmentsForHITAll).
       with(:HITId => 'hit_2').
       returns([{
         :AssignmentId => 'a_5',
         :AssignmentStatus => 'Submitted'
       }])

    # expect the 2 Submitted assignments to be approved
    sb.stubs(:approveAssignment).once.with(:AssignmentId => 'a_1')
    sb.stubs(:approveAssignment).once.with(:AssignmentId => 'a_4')
    sb.stubs(:approveAssignment).once.with(:AssignmentId => 'a_5')

    response1.approve!
    response1.reload
    assert_equal true, response1.approved

    response2.approve!
    response2.reload
    assert_equal true, response2.approved
  end

  test "rejecting responses" do
    # create an eval with some questions and 3 tasks
    eval = create :evaluation

    task1 = create :task, :mturk_hit => 'hit_1', :evaluation => eval
    task2 = create :task, :mturk_hit => 'hit_2', :evaluation => eval

    response1 = create :task_response, :task => task1
    response2 = create :task_response, :task => task2

    sb = mturk_sandbox_mock

    # create a stub to provide a reasonable response for GetAssignmentForHITAll
    sb.stubs(:getAssignmentsForHITAll).
       with(:HITId => 'hit_1').
       returns([{
         :AssignmentId => 'a_1',
         :AssignmentStatus => 'Submitted'
       }, {
         :AssignmentId => 'a_2',
         :AssignmentStatus => 'Rejected'
       }, {
         :AssignmentId => 'a_4',
         :AssignmentStatus => 'Submitted'
       }])

    sb.stubs(:getAssignmentsForHITAll).
       with(:HITId => 'hit_2').
       returns([{
         :AssignmentId => 'a_5',
         :AssignmentStatus => 'Submitted'
       }])

    # expect the 2 Submitted assignments to be approved
    sb.stubs(:rejectAssignment).once.with(:AssignmentId => 'a_1')
    sb.stubs(:rejectAssignment).once.with(:AssignmentId => 'a_4')
    sb.stubs(:rejectAssignment).once.with(:AssignmentId => 'a_5')

    response1.reject!
    response1.reload
    assert_equal false, response1.approved

    response2.reject!
    response2.reload
    assert_equal false, response2.approved
  end
end