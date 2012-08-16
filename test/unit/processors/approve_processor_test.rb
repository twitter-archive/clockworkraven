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

class ApproveProcessorTest < ActiveSupport::TestCase
  test "process" do
    eval = create :evaluation
    task1 = create :task, :evaluation => eval, :mturk_hit => 'hit_1'
    task2 = create :task, :evaluation => eval, :mturk_hit => 'hit_2'
    task3 = create :task, :evaluation => eval, :mturk_hit => 'hit_3'

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
       }])

    sb.stubs(:getAssignmentsForHITAll).
       with(:HITId => 'hit_2').
       returns([{
         :AssignmentId => 'a_3',
         :AssignmentStatus => 'Submitted'
       }, {
         :AssignmentId => 'a_4',
         :AssignmentStatus => 'Submitted'
       }])

    sb.stubs(:getAssignmentsForHITAll).
       with(:HITId => 'hit_3').
       returns([{
         :AssignmentId => 'a_5',
         :AssignmentStatus => 'Rejected'
       }, {
         :AssignmentId => 'a_6',
         :AssignmentStatus => 'Approved'
       }])

    # expect the 3 Submitted assignments to be approved
    sb.stubs(:approveAssignment).once.with(:AssignmentId => 'a_1')
    sb.stubs(:approveAssignment).once.with(:AssignmentId => 'a_3')
    sb.stubs(:approveAssignment).once.with(:AssignmentId => 'a_4')

    processor = ApproveProcessor.new(FactoryGirl.generate(:resque_uuid))
    processor.process task1.id
    processor.process task2.id
    processor.process task3.id
  end

  test "after" do
    eval = create :evaluation

    processor = ApproveProcessor.new(FactoryGirl.generate(:resque_uuid))
    processor.stubs(:options).returns('evaluation_id' => eval.id)

    processor.after

    # check that processor.before updated the status of the evaluation
    assert_equal :approved, eval.reload.status_name
  end
end