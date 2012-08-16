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

class EvaluationsShowTest < ActionController::TestCase
  tests EvaluationsController

  setup do
    login
  end

  test "Sandbox/production shown correctly" do
    e = create :evaluation, :prod => 0
    get :show, :id => e.id
    assert_html_includes 'Sandbox Job'
    assert_html_includes 'There is no cost to deploy to the sandbox.'


    e = create :evaluation_with_tasks, :prod => 1, :task_count => 5, :payment => 100
    get :show, :id => e.id
    assert_html_includes 'Production Job'
    assert_html_includes "The total cost is $5.50"
  end

  test "Actions for new eval" do
    e = create :evaluation, :status => 0
    get :show, :id => e.id
    assert_select 'a:content("Edit Properties")'
    assert_select 'a:content("Edit Template")'
    assert_select 'a:content("Submit to MTurk")'
  end

  test "Actions and respose count for submitted eval" do
    e = create :evaluation, :status => 1

    # mock out available results count
    e.expects(:available_results_count).returns(179)
    Evaluation.stubs(:find).with(e.id.to_s).returns(e)

    get :show, :id => e.id
    assert_select 'a:content("View on MTurk")'
    assert_select 'a:content("Close Evaluation")'
    assert_select 'p:content("179")'
  end

  test "Actions for closed eval" do
    e = create :evaluation, :status => 2
    get :show, :id => e.id
    assert_select 'a:content("View Responses")'
    assert_select 'a:content("Approve All Unapproved Responses")'
  end

  test "Actions for approved eval" do
    e = create :evaluation, :status => 3
    get :show, :id => e.id
    assert_select 'a:content("View Responses")'
    assert_select 'a:content("Remove from MTurk")'
  end

  test "Actions for purged eval" do
    e = create :evaluation, :status => 4
    get :show, :id => e.id
    assert_select 'a:content("View Responses")'
  end
end