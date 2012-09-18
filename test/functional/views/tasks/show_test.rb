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

class TasksShowTest < ActionController::TestCase
  tests TasksController

  setup do
    login
    get_page
  end

  test "first header shown" do
    assert_select "h1:content('Header 1')"
  end

  test "text shown and interpolated" do
    assert_select "div:content('item 1 is #{@task.data['item1']}.')"
  end

  test "second header shown and interpolated" do
    assert_select "h1:content('Item 2 Is: #{@task.data['item2']}')"
  end

  test "tweet shown" do
    assert_select ".section > blockquote.twitter-tweet > a[href=http://twitter.com/#{@task.data['tweet']}]"
  end

  test "user link shown" do
    assert_select "a:content(@benweissmann)"
  end

  test "user shown" do
    # location not shown
    assert !response.body.include?('Location:')

    # username shown
    assert_select "a:content(@echen)"

    # tweets shown
    assert_select ".timeline a[href=http://twitter.com/#{@task.data['tweet']}]"
  end

  test "MC questions and options shown" do
    @e.mc_questions.each do |q|
      next if q.metadata

      assert_select "legend:content('#{q.label}')"
      question_id = "mc:#{q.id}"
      q.mc_question_options.each do |opt|
        assert_select "input[type=radio][name=#{question_id}][value=#{opt.id}]"
      end
    end
  end

  test "MC Metadata not shown" do
    @e.mc_questions.each do |q|
      next unless q.metadata
      assert !response.body.include?(q.label)
    end
  end

  test "FR questions shown" do
    @e.fr_questions.each do |q|
      assert_select "textarea[name=fr:#{q.id}]"
    end
  end

  test "Tweet javascript only included once" do
    assert_select "script[src='//platform.twitter.com/widgets.js']", 1
  end

  def get_page
    @e = create :evaluation_with_tasks_and_questions
    @task = @e.tasks.first
    get :show, :id => @task.id, :evaluation_id => @task.evaluation.id
  end
end