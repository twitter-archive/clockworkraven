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

class TaskResponsesControllerTest < ActionController::TestCase
  setup do
    login
  end

  test "index" do
    # The main thing to test is that assigns(:data) is set correctly.

    # Create an eval with 4 tasks, 3 of which have responses
    e = create :evaluation_with_tasks_and_questions, :task_count => 4,
                                                     :mc_option_count => 3,
                                                     :options_have_values => true

    mc1 = e.mc_questions.first
    mc2 = e.mc_questions.second
    fr1 = e.fr_questions.first
    fr2 = e.fr_questions.second

    mc1_opt1 = mc1.mc_question_options.first
    mc1_opt2 = mc1.mc_question_options.second
    mc1_opt3 = mc1.mc_question_options.third

    mc2_opt1 = mc2.mc_question_options.first
    mc2_opt2 = mc2.mc_question_options.second
    mc2_opt3 = mc2.mc_question_options.third

    r1 = create :task_response,
                :task => e.tasks.first,
                :approved => nil,
                :work_duration => 10

    r1_mc1 = create :mc_question_response,
                    :task_response => r1,
                    :mc_question_option => mc1_opt1
    r1_mc2 = create :mc_question_response,
                    :task_response => r1,
                    :mc_question_option => mc2_opt2
    r1_fr1 = create :fr_question_response,
                    :task_response => r1,
                    :fr_question => fr1,
                    :response => "response 1"
    r1_fr1 = create :fr_question_response,
                    :task_response => r1,
                    :fr_question => fr2,
                    :response => "response 2"

    r2 = create :task_response,
                :task => e.tasks.second,
                :approved => false,
                :work_duration => 20

    r2_mc1 = create :mc_question_response,
                    :task_response => r2,
                    :mc_question_option => mc1_opt2
    r2_mc2 = create :mc_question_response,
                    :task_response => r2,
                    :mc_question_option => mc2_opt3
    r2_fr1 = create :fr_question_response,
                    :task_response => r2,
                    :fr_question => fr1,
                    :response => "response 3"
    r2_fr1 = create :fr_question_response,
                    :task_response => r2,
                    :fr_question => fr2,
                    :response => "response 4"

    r3 = create :task_response,
                :task => e.tasks.third,
                :approved => true,
                :work_duration => 30

    r3_mc1 = create :mc_question_response,
                    :task_response => r3,
                    :mc_question_option => mc1_opt3
    r3_mc2 = create :mc_question_response,
                    :task_response => r3,
                    :mc_question_option => mc2_opt1
    r3_fr1 = create :fr_question_response,
                    :task_response => r3,
                    :fr_question => fr1,
                    :response => "response 5"
    r3_fr1 = create :fr_question_response,
                    :task_response => r3,
                    :fr_question => fr2,
                    :response => "response 6"

    get :index, :evaluation_id => e.id
    assert_response :success
    assert_equal e, assigns(:eval)
    assert_equal [r1, r2, r3], assigns(:task_responses)

    expected_data = {
      :mcQuestions => {
        mc1.id => {
          :label => mc1.label,
          :options => [mc1_opt1.id, mc1_opt2.id, mc1_opt3.id]
        },
        mc2.id => {
          :label => mc2.label,
          :options => [mc2_opt1.id, mc2_opt2.id, mc2_opt3.id]
        }
      },
      :mcQuestionOptions => {
        mc1_opt1.id => {
          :label => mc1_opt1.label,
          :value => mc1_opt1.value,
          :question => mc1.id
        },
        mc1_opt2.id => {
          :label => mc1_opt2.label,
          :value => mc1_opt2.value,
          :question => mc1.id
        },
        mc1_opt3.id => {
          :label => mc1_opt3.label,
          :value => mc1_opt3.value,
          :question => mc1.id
        },
        mc2_opt1.id => {
          :label => mc2_opt1.label,
          :value => mc2_opt1.value,
          :question => mc2.id
        },
        mc2_opt2.id => {
          :label => mc2_opt2.label,
          :value => mc2_opt2.value,
          :question => mc2.id
        },
        mc2_opt3.id => {
          :label => mc2_opt3.label,
          :value => mc2_opt3.value,
          :question => mc2.id
        }
      },
      :frQuestions => {
        fr1.id => {
          :label => fr1.label
        },
        fr2.id => {
          :label => fr2.label
        }
      },
      :responses => {
        r1.id => {
          :mcQuestions => {mc1.id => mc1_opt1.id,  mc2.id => mc2_opt2.id},
          :frQuestions => {fr1.id => 'response 1', fr2.id => 'response 2'},
          :approved    => true
        },
        r2.id => {
          :mcQuestions => {mc1.id => mc1_opt2.id,  mc2.id => mc2_opt3.id},
          :frQuestions => {fr1.id => 'response 3', fr2.id => 'response 4'},
          :approved    => false
        },
        r3.id => {
          :mcQuestions => {mc1.id => mc1_opt3.id,  mc2.id => mc2_opt1.id},
          :frQuestions => {fr1.id => 'response 5', fr2.id => 'response 6'},
          :approved    => true
        }
      }
    }

    assert_equal HashWithIndifferentAccess.new(expected_data), assigns(:data)

    # test csv

    expected_csv = <<-END_CSV
      item1,item2,tweet,metadata1,metadata2,#{mc1.label},#{mc2.label},#{fr1.label},#{fr2.label},HIT ID,MTurk User,Work Duration,Approval
      #{r1.task.data["item1"]},#{r1.task.data["item2"]},#{r1.task.data["tweet"]},#{r1.task.data["metadata1"]},#{r1.task.data["metadata2"]},#{mc1_opt1.label},#{mc2_opt2.label},response 1,response 2,#{r1.task.mturk_hit},#{r1.m_turk_user_id},10,false
      #{r2.task.data["item1"]},#{r2.task.data["item2"]},#{r2.task.data["tweet"]},#{r2.task.data["metadata1"]},#{r2.task.data["metadata2"]},#{mc1_opt2.label},#{mc2_opt3.label},response 3,response 4,#{r2.task.mturk_hit},#{r2.m_turk_user_id},20,false
      #{r3.task.data["item1"]},#{r3.task.data["item2"]},#{r3.task.data["tweet"]},#{r3.task.data["metadata1"]},#{r3.task.data["metadata2"]},#{mc1_opt3.label},#{mc2_opt1.label},response 5,response 6,#{r3.task.mturk_hit},#{r3.m_turk_user_id},30,true
    END_CSV
    expected_csv = expected_csv.lines.map{|line| line.lstrip}.join

    get :index, :format => 'csv', :evaluation_id => e.id
    assert_equal expected_csv, response.body

    # test tsv

    expected_tsv = <<-END_TSV
      item1\titem2\ttweet\tmetadata1\tmetadata2\t#{mc1.label}\t#{mc2.label}\t#{fr1.label}\t#{fr2.label}\tHIT ID\tMTurk User\tWork Duration\tApproval
      #{r1.task.data["item1"]}\t#{r1.task.data["item2"]}\t#{r1.task.data["tweet"]}\t#{r1.task.data["metadata1"]}\t#{r1.task.data["metadata2"]}\t#{mc1_opt1.label}\t#{mc2_opt2.label}\tresponse 1\tresponse 2\t#{r1.task.mturk_hit}\t#{r1.m_turk_user_id}\t10\tfalse
      #{r2.task.data["item1"]}\t#{r2.task.data["item2"]}\t#{r2.task.data["tweet"]}\t#{r2.task.data["metadata1"]}\t#{r2.task.data["metadata2"]}\t#{mc1_opt2.label}\t#{mc2_opt3.label}\tresponse 3\tresponse 4\t#{r2.task.mturk_hit}\t#{r2.m_turk_user_id}\t20\tfalse
      #{r3.task.data["item1"]}\t#{r3.task.data["item2"]}\t#{r3.task.data["tweet"]}\t#{r3.task.data["metadata1"]}\t#{r3.task.data["metadata2"]}\t#{mc1_opt3.label}\t#{mc2_opt1.label}\tresponse 5\tresponse 6\t#{r3.task.mturk_hit}\t#{r3.m_turk_user_id}\t30\ttrue
    END_TSV
    expected_tsv = expected_tsv.lines.map{|line| line.lstrip}.join

    get :index, :format => 'tsv', :evaluation_id => e.id
    assert_equal expected_tsv, response.body
  end

  # This asserts that a method that normally returns a JSON response requires
  # a privileged user.
  #
  # protected_method: This is the method that should get called on the
  #                   task response when the block is executed by a privileged
  #                   user.
  # success_status:   If the block executes as a privileged user, it is expected
  #                   to render the JSON: {:status => <success_status>}
  # block:            This block should send a request to the controller that
  #                   calls protected_method iff the current user is privileged
  def assert_require_priv protected_method, success_status
    e = create :evaluation, :prod => true
    task = create :task, :evaluation => e
    resp = create :task_response, :task => task

    TaskResponse.stubs(:find).with(resp.id.to_s).returns(resp)

    # assert that an unprivileged user gets a Forbidden response
    login
    resp.expects(protected_method).times(0)
    yield resp
    assert_response 403
    assert_equal({'status' => 'Forbidden'}, json_response)

    # assert that a privileged user can do it
    login_priv
    resp.expects(protected_method)
    yield resp
    assert_response :success
    assert_equal({'status' => success_status}, json_response)
  end

  test "approve" do
    resp = create :task_response
    resp.expects(:approve!)
    TaskResponse.expects(:find).with(resp.id.to_s).returns(resp)

    post :approve, :id => resp.id, :evaluation_id => resp.task.evaluation.id
    assert_response :success
    assert_equal({'status' => 'Approved'}, json_response)
  end

  test "approve requires privileged user" do
    assert_require_priv :approve!, 'Approved' do |resp|
      post :approve, :id => resp, :evaluation_id => resp.task.evaluation.id
    end
  end

  test "reject" do
    resp = create :task_response
    resp.expects(:reject!)
    TaskResponse.expects(:find).with(resp.id.to_s).returns(resp)

    post :reject, :id => resp.id, :evaluation_id => resp.task.evaluation.id
    assert_response :success
    assert_equal({'status' => 'Rejected'}, json_response)
  end

  test "reject requires privileged user" do
    assert_require_priv :reject!, 'Rejected' do |resp|
      post :reject, :id => resp, :evaluation_id => resp.task.evaluation.id
    end
  end
end