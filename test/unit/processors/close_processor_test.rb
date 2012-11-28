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

class CloseProcessorTest < ActiveSupport::TestCase
  test "closing tasks and importing results" do
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

    t1 = create :task, :mturk_hit => 'HIT_1', :evaluation => eval
    t1.data['metadata1'] = 'resp1a'
    t1.data['metadata2'] = 'resp2a'
    t1.save!

    t2 = create :task, :mturk_hit => 'HIT_2', :evaluation => eval
    t2.data['metadata1'] = 'resp1a'
    t2.data['metadata2'] = 'resp2b'
    t2.save!

    t3 = create :task, :mturk_hit => 'HIT_3', :evaluation => eval
    t3.data['metadata1'] = 'resp1b'
    t3.data['metadata2'] = 'resp2a'
    t3.save!

    # close! should get rid of existing task responses, so we make on here
    # to make sure it gets deleted
    create :task_response, :task => Task.find_by_mturk_hit('HIT_1')

    # we expect 3 calls to close the evaluations and 3 more to get the results
    sb = mturk_sandbox_mock

    sb.stubs(:forceExpireHIT).once.with({:HITId => 'HIT_1'})
    sb.stubs(:forceExpireHIT).once.with({:HITId => 'HIT_2'})
    sb.stubs(:forceExpireHIT).once.with({:HITId => 'HIT_3'})

    sb.stubs(:getAssignmentsForHIT).once.with({:HITId => 'HIT_1'}).returns({
      :Assignment => {
        :AssignmentId => 'FooAssignment',
        :WorkerId => 'FooWorker',
        :HITId => 'HIT_1',
        :AssignmentStatus => 'Submitted',
        :AutoAprovalTime => 3.days.from_now,
        :AcceptTime => 100.minutes.ago,
        :SubmitTime => 98.minutes.ago,
        :Answer => answer_xml("fr:#{fr1.id}" => 'Answer_1_1',
                              "fr:#{fr2.id}" => 'Answer_2_1',
                              "mc:#{mc1.id}" => mc1_1.id,
                              "mc:#{mc2.id}" => mc2_1.id)
      }
    })

    sb.stubs(:getAssignmentsForHIT).once.with({:HITId => 'HIT_2'}).returns({
      :Assignment => {
        :AssignmentId => 'BarAssignment',
        :WorkerId => 'FooWorker',
        :HITId => 'HIT_2',
        :AssignmentStatus => 'Submitted',
        :AutoAprovalTime => 3.days.from_now,
        :AcceptTime => 90.minutes.ago,
        :SubmitTime => 87.minutes.ago,
        :Answer => answer_xml("fr:#{fr1.id}" => 'Answer_1_2',
                              "fr:#{fr2.id}" => 'Answer_2_2',
                              "mc:#{mc1.id}" => mc1_1.id,
                              "mc:#{mc2.id}" => mc2_2.id)
      }
    })

    sb.stubs(:getAssignmentsForHIT).once.with({:HITId => 'HIT_3'}).returns({
      :Assignment => {
        :AssignmentId => 'BazAssignment',
        :WorkerId => 'BarWorker',
        :HITId => 'HIT_3',
        :AssignmentStatus => 'Submitted',
        :AutoAprovalTime => 3.days.from_now,
        :AcceptTime => 80.minutes.ago,
        :SubmitTime => 76.minutes.ago,
        :Answer => answer_xml("fr:#{fr1.id}" => 'Answer_1_3',
                              "fr:#{fr2.id}" => 'Answer_2_3',
                              "mc:#{mc1.id}" => mc1_2.id,
                              "mc:#{mc2.id}" => mc2_1.id)
      }
    })

    # actually call the code to close tasks and import results
    processor = CloseProcessor.new(FactoryGirl.generate(:resque_uuid))
    processor.process t1.id
    processor.process t2.id
    processor.process t3.id

    # run #after and make sure completion is getting incremented
    processor.instance_variable_set :@items, [t1.id, t2.id, t3.id]
    processor.expects(:increment_completion).times(3)
    processor.stubs(:options).returns('evaluation_id' => eval.id)
    processor.after

    # check that there are the corrct number of TaskResponses and status was updated
    eval.reload
    assert_equal 3, eval.task_responses.size
    assert_equal :closed, eval.status_name

    # check that each task responses is correct

    # task 1
    response_1 = eval.tasks.find_by_mturk_hit('HIT_1').task_response

    # correct number of responses?
    #assert_equal 4, response_1.mc_question_responses.size
    assert_equal 2, response_1.fr_question_responses.size

    # work duration and worker set correctly?
    assert_in_delta (60*2), response_1.work_duration, 0.1
    assert_equal 'FooWorker', response_1.m_turk_user.id

    # multiple-choice questions - assert there is a response that belongs to
    # this TaskResponse and the correct option. Check both actual questions
    # and metadata
    assert_not_nil mc1_1.mc_question_responses.where(
      :task_response_id => response_1.id
    ).first

    assert_not_nil mc2_1.mc_question_responses.where(
      :task_response_id => response_1.id
    ).first

    # metadata
    assert_not_nil MCQuestion.find_by_label('metadata1').
                              mc_question_options.
                              where(:label => 'resp1a').
                              first.mc_question_responses.where(

      :task_response_id => response_1.id,
    ).first

    assert_not_nil MCQuestion.find_by_label('metadata2').
                              mc_question_options.
                              where(:label => 'resp2a').
                              first.mc_question_responses.where(

      :task_response_id => response_1.id,
    ).first

    # free-response questions
    assert_not_nil FRQuestionResponse.where(
      :task_response_id => response_1.id,
      :fr_question_id => fr1.id,
      :response => "Answer_1_1"
    ).first

    assert_not_nil FRQuestionResponse.where(
      :task_response_id => response_1.id,
      :fr_question_id => fr2.id,
      :response => "Answer_2_1"
    ).first

    # task 2
    response_2 = eval.tasks.find_by_mturk_hit('HIT_2').task_response

    # correct number of responses?
    assert_equal 4, response_2.mc_question_responses.size
    assert_equal 2, response_2.fr_question_responses.size

    # work duration and worker set correctly?
    assert_in_delta (60*3), response_2.work_duration, 0.1
    assert_equal 'FooWorker', response_2.m_turk_user.id

    # multiple-choice questions - assert there is a response that belongs to
    # this TaskResponse and the correct option. Check both actual questions
    # and metadata
    assert_not_nil mc1_1.mc_question_responses.where(
      :task_response_id => response_2.id
    ).first

    assert_not_nil mc2_2.mc_question_responses.where(
      :task_response_id => response_2.id
    ).first

    # metadata
    assert_not_nil MCQuestion.find_by_label('metadata1').
                              mc_question_options.
                              where(:label => 'resp1a').
                              first.
                              mc_question_responses.
                              where(
      :task_response_id => response_2.id,
    ).first

    assert_not_nil MCQuestion.find_by_label('metadata2').
                              mc_question_options.
                              where(:label => 'resp2b').
                              first.
                              mc_question_responses.
                              where(
      :task_response_id => response_2.id,
    ).first

    # free-response questions
    assert_not_nil FRQuestionResponse.where(
      :task_response_id => response_2.id,
      :fr_question_id => fr1.id,
      :response => "Answer_1_2"
    ).first

    assert_not_nil FRQuestionResponse.where(
      :task_response_id => response_2.id,
      :fr_question_id => fr2.id,
      :response => "Answer_2_2"
    ).first

    # task 3
    response_3 = eval.tasks.find_by_mturk_hit('HIT_3').task_response

    # correct number of responses?
    assert_equal 4, response_3.mc_question_responses.size
    assert_equal 2, response_3.fr_question_responses.size

    # work duration and worker set correctly?
    assert_in_delta (60*4), response_3.work_duration, 0.1
    assert_equal 'BarWorker', response_3.m_turk_user.id

    # multiple-choice questions - assert there is a response that belongs to
    # this TaskResponse and the correct option. Check both actual questions
    # and metadata
    assert_not_nil mc1_2.mc_question_responses.where(
      :task_response_id => response_3.id
    ).first

    assert_not_nil mc2_1.mc_question_responses.where(
      :task_response_id => response_3.id
    ).first

    # metadata
    assert_not_nil MCQuestion.find_by_label('metadata1').
                              mc_question_options.
                              where(:label => 'resp1b').
                              first.
                              mc_question_responses.
                              where(
      :task_response_id => response_3.id,
    ).first

    assert_not_nil MCQuestion.find_by_label('metadata2').
                              mc_question_options.
                              where(:label => 'resp2a').
                              first.
                              mc_question_responses.
                              where(
      :task_response_id => response_3.id,
    ).first


    # free-response questions
    assert_not_nil FRQuestionResponse.where(
      :task_response_id => response_3.id,
      :fr_question_id => fr1.id,
      :response => "Answer_1_3"
    ).first

    assert_not_nil FRQuestionResponse.where(
      :task_response_id => response_3.id,
      :fr_question_id => fr2.id,
      :response => "Answer_2_3"
    ).first
  end

  # we also test behavior when we have only one question, because we get
  # slightly different XML from MTurk.
  test "closing tasks and importing results, single question" do
    # create an eval with some questions and 3 tasks
    eval = create :evaluation_with_questions, :fr_count => 0, :mc_count => 1, :metadata => []

    mc1 = eval.mc_questions.first
    mc1_1 = mc1.mc_question_options.first
    mc1_2 = mc1.mc_question_options.second

    t1 = create :task, :mturk_hit => 'HIT_1', :evaluation => eval
    t2 = create :task, :mturk_hit => 'HIT_2', :evaluation => eval

    # we expect 2 calls to close the evaluations and 2 more to get the results
    sb = mturk_sandbox_mock

    sb.stubs(:forceExpireHIT).once.with({:HITId => 'HIT_1'})
    sb.stubs(:forceExpireHIT).once.with({:HITId => 'HIT_2'})

    sb.stubs(:getAssignmentsForHIT).once.with({:HITId => 'HIT_1'}).returns({
      :Assignment => {
        :AssignmentId => 'FooAssignment',
        :WorkerId => 'FooWorker',
        :HITId => 'HIT_1',
        :AssignmentStatus => 'Submitted',
        :AutoAprovalTime => 3.days.from_now,
        :AcceptTime => 100.minutes.ago,
        :SubmitTime => 98.minutes.ago,
        :Answer => answer_xml("mc:#{mc1.id}" => mc1_1.id)
      }
    })

    sb.stubs(:getAssignmentsForHIT).once.with({:HITId => 'HIT_2'}).returns({
      :Assignment => {
        :AssignmentId => 'BarAssignment',
        :WorkerId => 'FooWorker',
        :HITId => 'HIT_2',
        :AssignmentStatus => 'Submitted',
        :AutoAprovalTime => 3.days.from_now,
        :AcceptTime => 90.minutes.ago,
        :SubmitTime => 87.minutes.ago,
        :Answer => answer_xml("mc:#{mc1.id}" => mc1_2.id)
      }
    })


    # actually call the code to close tasks and import results
    processor = CloseProcessor.new(FactoryGirl.generate(:resque_uuid))
    processor.process t1.id
    processor.process t2.id

    # check that there are the corrct number of TaskResponses and status was updated
    eval.reload
    assert_equal 2, eval.task_responses.size

    # check that each task responses is correct

    # task 1
    response_1 = eval.tasks.find_by_mturk_hit('HIT_1').task_response

    # correct number of responses?
    assert_equal 1, response_1.mc_question_responses.size
    assert_equal 0, response_1.fr_question_responses.size

    # multiple-choice questions - assert there is a response that belongs to
    # this TaskResponse and the correct option. Check both actual questions
    # and metadata
    assert_not_nil mc1_1.mc_question_responses.where(
      :task_response_id => response_1.id
    ).first

    # task 2
    response_2 = eval.tasks.find_by_mturk_hit('HIT_2').task_response

    # correct number of responses?
    assert_equal 1, response_2.mc_question_responses.size
    assert_equal 0, response_2.fr_question_responses.size

    # multiple-choice questions - assert there is a response that belongs to
    # this TaskResponse and the correct option. Check both actual questions
    # and metadata
    assert_not_nil mc1_2.mc_question_responses.where(
      :task_response_id => response_2.id
    ).first
  end

  # Given a hash of question id => answer pairs, build the XML that would be
  # returned from MTurk for those pairs.
  def answer_xml answers
    out = <<-END_XML
      <?xml version="1.0" encoding="UTF-8"?>
      <QuestionFormAnswers xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionFormAnswers.xsd">
    END_XML

    answers.each do |q, a|
      out += <<-END_XML
        <Answer>
          <QuestionIdentifier>#{q}</QuestionIdentifier>
          <FreeText>#{a}</FreeText>
        </Answer>
      END_XML
    end

    out += "</QuestionFormAnswers>"

    return out
  end
end
