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

class TasksControllerTest < ActionController::TestCase
  setup do
    login
  end

  test "show" do
    task = create :task

    get :show, :id => task.id, :evaluation_id => task.evaluation.id

    assert_equal task, assigns(:task)
    assert_equal true, assigns(:mturk)
    assert_template :mturk
  end

  test "show_string" do
    # check that #show_string gives us the same result as rendering with #show
    eval = create :evaluation_with_questions
    task = create :task, :evaluation => eval

    get :show, :id => task.id, :evaluation_id => task.evaluation.id

    assert_equal response.body, @controller.show_string(task)
  end

  test "complete" do
    task = create :task

    get :complete, :id => task.id, :evaluation_id => task.evaluation.id

    assert_equal task, assigns(:task)
    assert_equal false, assigns(:mturk)
    assert_template :internal
  end

  test "submit" do
    # create an eval with some questions and 3 tasks
    eval = create :evaluation_with_questions

    mc1 = eval.mc_questions.first
    mc1_1 = mc1.mc_question_options.first
    mc1_2 = mc1.mc_question_options.second

    mc2 = eval.mc_questions.second
    mc2_1 = mc2.mc_question_options.first
    mc2_2 = mc2.mc_question_options.second

    fr1 = eval.fr_questions.first
    fr2 = eval.fr_questions.second

    task = create :task, :evaluation => eval, :mturk_hit => 'HIT_1'
    task.data['metadata1'] = 'resp1a'
    task.data['metadata2'] = 'resp2a'
    task.save!

    # close! should get rid of existing task responses, so we make on here
    # to make sure it gets deleted
    create :task_response, :task => task

    # we expect a call to close this task
    sb = mturk_sandbox_mock

    sb.stubs(:forceExpireHIT).once.with({:HITId => task.mturk_hit})

    params = {
      :id => task.id,
      :evaluation_id => eval.id,
      :start_time => 60.seconds.ago.to_i.to_s,
      :evaluation => {
        :mc_q => {
          mc1.id => mc1_1.id,
          mc2.id => mc2_2.id
        },
        :fr_q => {
          fr1.id => 'Answer_1',
          fr2.id => 'Answer_2'
        }
      }
    }

    post :submit, params

    # check that the task response is correct
    eval.reload
    assert_equal 1, eval.task_responses.size

    # task 1
    response = task.reload.task_response

    # correct number of responses?
    assert_equal 4, response.mc_question_responses.size
    assert_equal 2, response.fr_question_responses.size

    # work duration and worker set correctly?
    assert_in_delta 60, response.work_duration, 1
    assert_equal @user.username, response.m_turk_user.id

    # multiple-choice questions - assert there is a response that belongs to
    # this TaskResponse and the correct option. Check both actual questions
    # and metadata
    assert_not_nil MCQuestionResponse.where(
      :task_response_id => response.id,
      :mc_question_option_id => mc1_1.id
    ).first

    assert_not_nil MCQuestionResponse.where(
      :task_response_id => response.id,
      :mc_question_option_id => mc2_2.id
    ).first

    # metadata
    assert_not_nil MCQuestionResponse.where(
      :task_response_id => response.id,
      :mc_question_option_id => MCQuestion.find_by_label('metadata1').
                                           mc_question_options.
                                           where(:label => 'resp1a').
                                           first.id
    ).first

    assert_not_nil MCQuestionResponse.where(
      :task_response_id => response.id,
      :mc_question_option_id => MCQuestion.find_by_label('metadata2').
                                           mc_question_options.
                                           where(:label => 'resp2a').
                                           first.id
    ).first

    # free-response questions
    assert_not_nil FRQuestionResponse.where(
      :task_response_id => response.id,
      :fr_question_id => fr1.id,
      :response => "Answer_1"
    ).first

    assert_not_nil FRQuestionResponse.where(
      :task_response_id => response.id,
      :fr_question_id => fr2.id,
      :response => "Answer_2"
    ).first
  end
end