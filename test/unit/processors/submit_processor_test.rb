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

class SubmitProcessorTest < ActiveSupport::TestCase
  test "process" do
    eval = create :evaluation_with_tasks, :mturk_hit_type => 'ABCDEFG'
    task = eval.tasks.first
    sb = mturk_sandbox_mock

    sb.stubs(:createHIT).once.with({
      :HITTypeId => 'ABCDEFG',
      :Question => MTurkUtils.send(:build_question_xml, task.render),
      :LifetimeInSeconds => eval.lifetime,
      :MaxAssignments => 1,
      :UniqueRequestToken => task.uuid.to_s
    }).returns({
      :HITId => "HITID"
    })

    SubmitProcessor.new(FactoryGirl.generate(:resque_uuid)).process task.id

    assert_equal 'HITID', task.reload.mturk_hit
  end

  test "before" do
    eval = create :evaluation

    processor = SubmitProcessor.new(FactoryGirl.generate(:resque_uuid))
    processor.stubs(:options).returns('evaluation_id' => eval.id)

    processor.before

    # check that processor.before updated the status of the evaluation
    assert_equal :submitted, eval.reload.status_name
  end
end