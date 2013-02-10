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

class EvaluationsTest < ActiveSupport::TestCase
  def evaluation_path(eval)
    "#{ClockworkRaven::Application.mounted_path}/evaluations/#{eval.id}"
  end
  
  test "names must be present and unique" do
    eval = build :evaluation, :name => nil
    assert eval.invalid?, "evaluation without name was valid"

    eval = create :evaluation
    eval2 = build :evaluation, :name => eval.name
    assert eval2.invalid?, "evaliation with duplicate name was valid"

    eval3 = build :evaluation
    assert eval3.valid?, "evaluation with non-duplicate name was invalid"
  end

  test "title must be present" do
    eval = build :evaluation, :title => nil
    assert eval.invalid?, "evaluation without title was valid"

    eval.title = ' '
    assert eval.invalid?, "evaluation with blank title was valid"

    eval.title = 'valid'
    assert eval.valid?, "evaluation with title was invalid"
  end

  test "desc must be present" do
    eval = build :evaluation, :desc => nil
    assert eval.invalid?, "evaluation without desc was valid"

    eval.desc = ' '
    assert eval.invalid?, "evaluation with blank desc was valid"

    eval.desc = 'valid'
    assert eval.valid?, "evaluation with desc was invalid"
  end

  test "payment must be at least 1 cent" do
    eval = build :evaluation, :payment => 1
    assert eval.valid?, "evaluation with 1 cent payment was invalid"

    eval = build :evaluation, :payment => 0
    assert eval.invalid?, "evaluation with 0 cent payment was valid"
  end

  test "status must be between 0 and 4" do
    eval = build :evaluation, :status => 0
    assert eval.valid? "evaluation with status 0 was invalid"

    eval = build :evaluation, :status => 4
    assert eval.valid? "evaluation with status 4 was invalid"

    eval = build :evaluation, :status => -1
    assert eval.invalid? "evaluation with status -1 was valid"

    eval = build :evaluation, :status => 5
    assert eval.invalid? "evaluation with status 5 was valid"
  end

  test "mturk_qualification must be a valid value" do
    eval = build :evaluation, :mturk_qualification => 'none'
    assert eval.valid? "evaluation with qualification 'none' was invalid"

    eval = build :evaluation, :mturk_qualification => 'trusted'
    assert eval.valid? "evaluation with qualification 'trusted' was invalid"

    eval = build :evaluation, :mturk_qualification => 'master'
    assert eval.valid? "evaluation with qualification 'master' was invalid"

    eval = build :evaluation, :mturk_qualification => 'foo'
    assert eval.invalid? "evaluation with qualification 'foo' was valid"
  end

  test "mc question order" do
    # metadata comes after non-metadata, non-metadata ordered by `order` col
    eval = create :evaluation
    q1 = create :mc_question, :evaluation => eval, :order => 2
    m1 = create :mc_question, :evaluation => eval, :metadata => true
    q2 = create :mc_question, :evaluation => eval, :order => 3
    m2 = create :mc_question, :evaluation => eval, :metadata => true
    q3 = create :mc_question, :evaluation => eval, :order => 1

    assert_equal [q3, q1, q2, m1, m2], eval.mc_questions
  end

  test "fr question order" do
    # ordered by the `order` column
    eval = create :evaluation
    q1 = create :fr_question, :evaluation => eval, :order => 3
    q2 = create :fr_question, :evaluation => eval, :order => 1
    q3 = create :fr_question, :evaluation => eval, :order => 2

    assert_equal [q2, q3, q1], eval.fr_questions
  end

  test "add tasks" do
    eval = create :evaluation

    expected_task_1_data = {
      "foo1" => "bar1",
      "foo2" => "bar2"
    }

    expected_task_2_data = {
      "foo1" => "bar3",
      "foo2" => "bar4"
    }

    tasks = eval.add_tasks(parse_json_fixture('data1.json'))

    assert_equal 2, eval.tasks.size, "didn't add 2 Tasks to the Evaluation"
    assert_equal expected_task_1_data, eval.tasks.first.data, "Evaluation's Task 1 data incorrect"
    assert_equal expected_task_2_data, eval.tasks.second.data, "Evaluation's Task 2 data incorrect"
    assert_equal 2, tasks.size, "didn't return 2 Tasks"
    assert_equal expected_task_1_data, tasks.first.data, "Returned Task 1 data incorrect"
    assert_equal expected_task_2_data, tasks.second.data, "Returned Task 2 data incorrect"
  end

  test "add task" do
    eval = create :evaluation

    expected_task_data = {
      "foo1" => "bar1",
      "foo2" => "bar2"
    }

    task = eval.add_task(expected_task_data)

    assert_equal expected_task_data, task.data
    assert_equal 1, eval.tasks.size
    assert_equal expected_task_data, eval.tasks.first.data
  end

  test "original data column names" do
    eval = create :evaluation

    assert_equal 0, eval.original_data_column_names.size, "Column names for eval without data incorrect"

    eval.add_tasks(parse_json_fixture('data1.json'))
    expected_column_names = %w(foo1 foo2)

    assert_equal expected_column_names, eval.original_data_column_names, "Column names for eval incorrect"
  end

  test "random task" do
    eval = create :evaluation_with_tasks, :task_count => 2
    task = eval.random_task
    assert (task == eval.tasks.first) || (task == eval.tasks.second)

    # test random eval with no tasks
    eval = create :evaluation
    task = eval.random_task
    assert task.nil?
  end

  test "status names" do
    Evaluation::STATUS_ID.each do |name, id|
      eval = build :evaluation, :status => id
      assert_equal name, eval.status_name, "Eval with id #{id} had incorrect name"
    end
  end

  test "mechanical turk url" do
    prod_eval = build :evaluation, :prod => 1, :mturk_hit_type => 'foo_hit_type'
    assert_equal "http://mturk.com/mturk/preview?groupId=foo_hit_type", prod_eval.mturk_url

    sandbox_eval = build :evaluation, :mturk_hit_type => 'bar_hit_type'
    assert_equal "http://workersandbox.mturk.com/mturk/preview?groupId=bar_hit_type", sandbox_eval.mturk_url
  end

  test "available results count" do
    # test prod
    prod_eval = build :evaluation, :prod => 1

    prod = mturk_prod_mock
    prod.expects(:getReviewableHITs).
         with({:HITTypeId => prod_eval.mturk_hit_type}).
         returns({:TotalNumResults => 3})

    assert_equal 3, prod_eval.available_results_count

    # test sandbox
    sandbox_eval = build :evaluation, :prod => 0

    sb = mturk_sandbox_mock
    sb.expects(:getReviewableHITs).
       with({:HITTypeId => prod_eval.mturk_hit_type}).
       returns({:TotalNumResults => 4})

    assert_equal 4, sandbox_eval.available_results_count
  end

  test "qualification type" do
    e = build :evaluation, :prod => 0, :mturk_qualification => 'trusted'
    assert_equal MTURK_CONFIG[:qualifications][:trusted][:sandbox], e.mturk_qualification_type

    e = build :evaluation, :prod => 1, :mturk_qualification => 'master'
    assert_equal MTURK_CONFIG[:qualifications][:master][:prod], e.mturk_qualification_type

    e = build :evaluation, :prod => 1, :mturk_qualification => 'none'
    assert_equal nil, e.mturk_qualification_type
  end

  test "copying evaluations" do
    # build an evaluation. make sure its properties aren't set to the defaults
    # set in SQL -- we want to make sure, when we copy it, that the values are
    # taken from this eval, not set to the defaults.
    eval = create :evaluation_with_questions, {
      :status              => 3,
      :mturk_qualification => "master",
      :prod                => 1,
      :duration            => 1800,
      :options_have_values => true,
      :metadata            => ['a', 'b'],
      :template            => [{:type => 'tweet', :data => {:tweet_id => '1234'}}]
    }

    fr_q = eval.fr_questions.first
    fr_q.required = false
    fr_q.save!

    copy = Evaluation.based_on eval
    # make sure properties that should be copied are copied
    [:desc, :keywords, :payment, :duration, :lifetime, :auto_approve,
     :mturk_qualification, :title, :metadata, :template, :note, :prod].each do |field|

      assert_equal eval[field], copy[field], "Field #{field} was not copied"
    end

    # fill in name and user id so we can save and use associations
    copy.name = "foo"
    copy.user = create(:user)
    copy.save!

    # make sure free-response questions were copied by value, not reference.
    eval.fr_questions.except(:order).order('label').all.each_with_index do |fr_q, i|
      q_copy = copy.fr_questions.except(:order).order('label').all[i]
      assert_equal fr_q.label, q_copy.label, "FR question #{i} was not copied"
      assert_equal fr_q.required, q_copy.required, "FR question #{i} was not copied"
      assert_not_equal fr_q.id, q_copy.id, "FR question #{i} was copied by reference"
    end

    # make sure multiple-choice questions were copied by value, not reference
    eval.mc_questions.except(:order).order('label').all.each_with_index do |mc_q, i|
      q_copy = copy.mc_questions.except(:order).order('label').all[i]
      assert_equal mc_q.label, q_copy.label, "MC question #{i} was not copied"
      assert_not_equal mc_q.id, q_copy.id, "MC question #{i} was copied by reference"

      # make sure options were copied by value, not reference
      mc_q.mc_question_options.except(:order).order('label').each_with_index do |opt, j|
        opt_copy = q_copy.mc_question_options.except(:order).order('label').all[j]
        assert_equal opt.label, opt_copy.label, "MC question #{i}, option #{j} label was not copied"
        assert_equal opt.value, opt_copy.value, "MC question #{i}, option #{j} value was not copied"
        assert_not_equal opt.id, opt_copy.id, "MC question #{i}, option #{j} was copied by reference"
      end
    end
  end

  test "submiting eval" do
    eval = create :evaluation_with_tasks, :task_count => 3,
                                          :desc => 'foo',
                                          :mturk_qualification => 'trusted'

    task_ids = [eval.tasks.first.id, eval.tasks.second.id, eval.tasks.third.id]

    sb = mturk_sandbox_mock

    # stub for submitting hit type
    sb.expects(:registerHITType).with({
      :Title => eval.title,
      :Description => "foo (CR ID: #{eval.id})",
      :Reward => {:CurrencyCode => 'USD', :Amount => eval.payment/100.0 },
      :AssignmentDurationInSeconds => eval.duration,
      :Keywords => eval.keywords,
      :AutoApprovalDelayInSeconds => eval.auto_approve,
      :QualificationRequirement => [{
        :Comparator => 'Exists',
        :QualificationTypeId => eval.mturk_qualification_type,
        :RequiredToPreview => true
      }]
    }).returns({
      :HITTypeId => 'ABCDEFG'
    })

    # stub for running the submission job. The correctness of the job
    # itself it tested in SubmitProcessorTest
    mock_job = mock
    mock_job.expects(:run).
             with(SubmitProcessor, task_ids, :evaluation_id => eval.id)

    Job.expects(:create).
        with(:complete_url => evaluation_path(eval),
             :back_url     => evaluation_path(eval),
             :title        => "Submitting Tasks").
        returns(mock_job)

    # make sure the eval's job gets set
    eval.expects(:job=).with(mock_job)

    eval.submit!
  end

  test "closing eval" do
    eval = create :evaluation_with_tasks, :task_count => 3

    task_ids = [eval.tasks.first.id, eval.tasks.second.id, eval.tasks.third.id]

    # stub for running the close job. The correctness of the job
    # itself it tested in CloseProcessorTest
    mock_job = mock
    mock_job.expects(:run).
             with(CloseProcessor, task_ids, :evaluation_id => eval.id)

    Job.expects(:create).
        with(:complete_url => evaluation_path(eval),
             :back_url     => evaluation_path(eval),
             :title        => "Closing Tasks").
        returns(mock_job)

    # make sure the eval's job gets set
    eval.expects(:job=).with(mock_job)

    eval.close!
  end

  test "approving eval" do
    eval = create :evaluation_with_tasks, :task_count => 3

    task_ids = [eval.tasks.first.id, eval.tasks.second.id, eval.tasks.third.id]

    # stub for running the close job. The correctness of the job
    # itself it tested in ApproveProcessorTest
    mock_job = mock
    mock_job.expects(:run).
             with(ApproveProcessor, task_ids, :evaluation_id => eval.id)

    Job.expects(:create).
        with(:complete_url => evaluation_path(eval),
             :back_url     => evaluation_path(eval),
             :title        => "Approving Tasks").
        returns(mock_job)

    # make sure the eval's job gets set
    eval.expects(:job=).with(mock_job)

    eval.approve_all!
  end

  test "purging eval" do
    eval = create :evaluation_with_tasks, :task_count => 3

    task_ids = [eval.tasks.first.id, eval.tasks.second.id, eval.tasks.third.id]

    # stub for running the close job. The correctness of the job
    # itself it tested in PurgeProcessorTest
    mock_job = mock
    mock_job.expects(:run).
             with(PurgeProcessor, task_ids, :evaluation_id => eval.id)

    Job.expects(:create).
        with(:complete_url => evaluation_path(eval),
             :back_url     => evaluation_path(eval),
             :title        => "Removing Tasks").
        returns(mock_job)

    # make sure the eval's job gets set
    eval.expects(:job=).with(mock_job)

    eval.purge_from_mturk!
  end

  test "calculating job cost" do
    # Cost is (payment + commmission) * (number of tasks)
    # Commission is 10%, minimum 0.5 cents

    # basic test. (10 + 1) *  5 = 55
    eval1 = create :evaluation_with_tasks, :task_count => 5, :payment => 10
    assert_equal 55, eval1.cost

    # no tasks. (20 + 2) * 0 = 0
    eval2 = create :evaluation, :payment => 20
    assert_equal 0, eval2.cost

    # using minimum commission. (2 + 0.5) * 10 = 25
    eval3 = create :evaluation_with_tasks, :task_count => 10, :payment => 2
    assert_equal 25, eval3.cost
  end

  test "calculating mean and median times and pay rates" do
    # payment $0.35, times: 5, 7, 8, 9, 10, 15
    # mean: 9, median: 8.5
    # mean rate: $140.00/hr, median rate: $148.00/hr
    eval1 = create :evaluation, :payment => 35
    [5, 7, 8, 9, 10, 15].each do |time|
      task = create :task, :evaluation => eval1
      create :task_response, :task => task, :work_duration => time
    end
    assert_equal 9, eval1.mean_time
    assert_equal 8.5, eval1.median_time
    assert_equal 14000, eval1.mean_pay_rate
    assert_in_delta 14823, eval1.median_pay_rate, 1

    # payment $0.15, times: 0, 10, 35
    # mean: 15, median: 10
    # mean rate: $36.00/hr, median rate: $54.00/hr
    eval2 = create :evaluation, :payment => 15
    [0, 10, 35].each do |time|
      task = create :task, :evaluation => eval2
      create :task_response, :task => task, :work_duration => time
    end
    assert_equal 15, eval2.mean_time
    assert_equal 10, eval2.median_time
    assert_equal 3600, eval2.mean_pay_rate
    assert_equal 5400, eval2.median_pay_rate

    # test 0 responses
    eval3 = create :evaluation
    assert_equal 0, eval3.mean_time
    assert_equal 0, eval3.median_time
    assert_equal 0, eval3.mean_pay_rate
    assert_equal 0, eval3.median_pay_rate

    # test mean/median of 0
    eval4 = create :evaluation
    [0, 0, 0].each do |time|
      task = create :task, :evaluation => eval4
      create :task_response, :task => task, :work_duration => time
    end
    assert_equal 0, eval4.mean_time
    assert_equal 0, eval4.median_time
    assert_equal 0, eval4.mean_pay_rate
    assert_equal 0, eval4.median_pay_rate
  end
end
