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

# Note: I don't test Task#add_metadata_as_questions here because
# the setup is fiarly involved, and it's already covered in
# EvaluationsTest#test_closing_tasks_and_importing_resuslts.
class TasksTest < ActiveSupport::TestCase
  test "rendering a task" do
    task = build :task

    rendering = task.render

    # Basic, permissive tests to make sure the data got rendered. We test the
    # output more extensively in test/funtional/views/tasks/show_test.rb

    assert rendering.include? 'Header 1'
    assert rendering.include? "item 1 is #{task.data['item1']}"
    assert rendering.include? "Item 2 Is: #{task.data['item2']}"
    assert rendering.include? '@benweissmann'
  end

  test "getting sandbox url" do
    eval = build :evaluation, :prod => 0
    task = build :task, :mturk_hit => 'foo_hit', :evaluation => eval

    assert_equal "http://requestersandbox.mturk.com/mturk/manageHIT?HITId=foo_hit", task.mturk_url
  end

  test "getting prod url" do
    eval = build :evaluation, :prod => 1
    task = build :task, :mturk_hit => 'bar_hit', :evaluation => eval

    assert_equal "http://requester.mturk.com/mturk/manageHIT?HITId=bar_hit", task.mturk_url
  end

  test "uuid" do
    # uuid created
    task = create :task
    assert_not_nil task.uuid

    # uuid not changed after a change to the task
    old_uuid = task.uuid
    task.data = {:a => 1, :b => 2}
    task.save!
    assert_equal old_uuid, task.reload.uuid

    # uuid unique
    task2 = create :task
    assert_not_equal task.uuid, task2.uuid
  end
end