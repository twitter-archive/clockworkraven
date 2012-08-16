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

class PurgeProcessorTest < ActiveSupport::TestCase
  test "process" do
    # Create an evaluation and some tasks that have HIT ids
    eval = create :evaluation
    FactoryGirl.create_list :submitted_task, 5, :evaluation => eval

    sb = mturk_sandbox_mock

    # expect each task to be disposed
    eval.tasks.each do |task|
      sb.stubs(:disposeHIT).once.with(:HITId => task.mturk_hit)
    end

    processor = PurgeProcessor.new(FactoryGirl.generate(:resque_uuid))
    eval.tasks.each { |t| processor.process t }
  end

  test "after" do
    eval = create :evaluation

    processor = PurgeProcessor.new(FactoryGirl.generate(:resque_uuid))
    processor.stubs(:options).returns('evaluation_id' => eval.id)

    processor.after

    # check that processor.before updated the status of the evaluation
    assert_equal :purged, eval.reload.status_name
  end
end