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
require 'set'

class EvaluationsControllerTest < ActionController::TestCase
  setup do
    login
  end

  teardown do
    logout
  end

  test "index" do
    # remove existing evaluations left over from other tests
    Evaluation.all.each{|eval| eval.destroy}

    # create two evaluations
    eval1 = create :evaluation
    eval2 = create :evaluation

    get :index

    # check that the controller responded correctly
    assert_response :success
    assert_equal 2, assigns(:evaluations).length
    assert_equal eval2, assigns(:evaluations).first
    assert_equal eval1, assigns(:evaluations).second
  end

  test "index pagination" do
    # remove existing evaluations left over from other tests
    Evaluation.all.each{|eval| eval.destroy}

    # make 12 evaluations
    evals = (0..11).map{ create :evaluation }

    # page 1 should be eval[11] through eval[2]
    get :index
    assert_response :success
    assert_equal evals[2..11].reverse, assigns(:evaluations)

    get :index, :page => 1
    assert_response :success
    assert_equal evals[2..11].reverse, assigns(:evaluations)

    # page 2 should be eval[1] and eval[0]
    get :index, :page => 2
    assert_response :success
    assert_equal evals[0..1].reverse, assigns(:evaluations)
  end

  test "show" do
    # create two evaluations
    eval1 = create :evaluation
    eval2 = create :evaluation

    # check that we can show them
    get :show, :id => eval1.id
    assert_response :success
    assert_equal eval1, assigns(:evaluation)

    get :show, :id => eval2.id
    assert_response :success
    assert_equal eval2, assigns(:evaluation)
  end

  test "new" do
    get :new
    assert_response :success
  end

  test "new based on" do
    eval = create :evaluation

    # we unit test Evaluation#based_on, so we can just mock and expect
    # the controller to use #based_on
    Evaluation.expects(:based_on).with(eval).returns(Evaluation.new)

    get :new, :based_on => eval.id
    assert_response :success
  end

  test "edit" do
    # create two evaluations
    eval1 = create :evaluation
    eval2 = create :evaluation

    # check that we can edit them
    get :edit, :id => eval1.id
    assert_response :success
    assert_equal eval1, assigns(:evaluation)

    get :edit, :id => eval2.id
    assert_response :success
    assert_equal eval2, assigns(:evaluation)
  end

  test "successful create" do
    ['tsv1.tsv', 'csv1.csv', 'data1.json'].each_with_index do |file, i|
      attrs = {
        :name                => "New eval #{i}",
        :payment             => 30,
        :auto_approve        => 86400,
        :note                => "Sample evaluation",
        :duration            => 3600,
        :desc                => "Choose a tweet",
        :keywords            => "twitter, mock, test",
        :title               => "Pick a tweet",
        :prod                => 0,
        :mturk_qualification => "none",
        :lifetime            => 604800,
        :data                => fixture_file_upload(file)
      }

      # assert we created a new evaluation
      assert_difference('Evaluation.count') do
        post :create, :evaluation => attrs
      end

      # assert correct redirection
      new_eval = Evaluation.last
      assert_redirected_to edit_template_evaluation_path(new_eval.id)
      assert_equal 'Evaluation was successfully created.', flash[:notice]

      # assert attributes set correctly
      attrs.each do |k, v|
        next if k == :data
        assert_equal v, new_eval[k] unless v.nil?
      end

      # check that user was set
      assert_equal @user, new_eval.user

      # assert data imported correctly
      assert_equal 2, new_eval.tasks.size
      assert_equal new_eval.tasks.first.data, {'foo1' => 'bar1', 'foo2' => 'bar2'}
      assert_equal new_eval.tasks.second.data, {'foo1' => 'bar3', 'foo2' => 'bar4'}
    end
  end

  test "unsuccessful create" do
    # we don't specify any of the required fields, so this should fail
    assert_no_difference('Evaluation.count') do
      post :create, :evaluation => {}
    end
  end

  test "update no new data" do
    e = create :evaluation

    post :update, :id => e.id, :evaluation => {:title => 'new title'}

    # we should redirect to show and flash a notice
    assert_redirected_to evaluation_path(e.id)
    assert_equal 'Evaluation was successfully updated.', flash[:notice]

    # and update the title
    assert_equal 'new title', Evaluation.find(e.id).title
  end

  test "update replace data" do
    # create an eval with the data from data1.json
    e = create :evaluation
    e.add_tasks parse_json_fixture('data1.json')

    # replace with the data from data2.json
    post :update, :id => e.id, :evaluation => {:data => fixture_file_upload('data2.json'),
                                               :replace_data => 1}
    assert_redirected_to evaluation_path(e.id)

    # assert data replaced correctly
    assert_equal e.tasks.size, 2
    assert_equal e.tasks.first.data, {'foo1' => 'bar5', 'foo2' => 'bar6'}
    assert_equal e.tasks.second.data, {'foo1' => 'bar7', 'foo2' => 'bar8'}

  end

  test "update replace data with TSV" do
    # create an eval with the data from data2.json
    e = create :evaluation
    e.add_tasks parse_json_fixture('data2.json')

    # replace with the data from tsv1.tsv
    post :update, :id => e.id, :evaluation => {:data => fixture_file_upload('tsv1.tsv'),
                                               :replace_data => 1}

    assert_redirected_to evaluation_path(e.id)

    # assert data replaced correctly.
    assert_equal 2, e.tasks.size
    assert_equal e.tasks.first.data, {'foo1' => 'bar1', 'foo2' => 'bar2'}
    assert_equal e.tasks.second.data, {'foo1' => 'bar3', 'foo2' => 'bar4'}

  end

  BAD_FILES = ['bad1.tsv', 'bad2.json', 'bad3.json', 'bad4.json', 'bad5.json', 'bad6.json']

  test "update with bad data" do
    BAD_FILES.each do |file|
      e = create :evaluation

      put :update, :id => e.id, :evaluation => {:data => fixture_file_upload(file)}
      assert_response :success
      assert flash[:error].starts_with?('Could not parse data')
    end
  end

  test "create with bad data" do
    BAD_FILES.each do |file|
      attrs = {
        :name                => "New eval",
        :payment             => 30,
        :auto_approve        => 86400,
        :note                => "Sample evaluation",
        :duration            => 3600,
        :desc                => "Choose a tweet",
        :keywords            => "twitter, mock, test",
        :title               => "Pick a tweet",
        :prod                => 0,
        :mturk_qualification => "none",
        :lifetime            => 604800,
        :data                => fixture_file_upload(file)
      }

      post :create, :evaluation => attrs
      assert_response :success
      assert flash[:error].starts_with?('Could not parse data')
    end
  end

  test "update add data" do
    # create an eval with the data from task1.json
    e = create :evaluation
    e.add_tasks parse_json_fixture('data1.json')

    # add the data from task2.json
    post :update, :id => e.id, :evaluation => {:data => fixture_file_upload('data2.json')}
    assert_redirected_to evaluation_path(e.id)

    # assert data added correctly
    assert_equal 4, e.tasks.size
    assert_equal e.tasks.first.data, {'foo1' => 'bar1', 'foo2' => 'bar2'}
    assert_equal e.tasks.second.data, {'foo1' => 'bar3', 'foo2' => 'bar4'}
    assert_equal e.tasks.third.data, {'foo1' => 'bar5', 'foo2' => 'bar6'}
    assert_equal e.tasks.fourth.data, {'foo1' => 'bar7', 'foo2' => 'bar8'}
  end

  test "destroy" do
    e = create :evaluation_with_tasks_and_questions

    eval_id = e.id
    task_ids = e.tasks.map{|task| task.id}
    mc_question_ids = e.mc_questions.map{|q| q.id}
    fr_question_ids = e.fr_questions.map{|q| q.id}

    # perform the destroy and assert redirected to eval index
    delete :destroy, :id => eval_id
    assert_redirected_to :controller => :evaluations, :action => :index

    # assert that dependant objects were destroyed
    assert_raise(ActiveRecord::RecordNotFound) { Evaluation.find eval_id }

    task_ids.each do |id|
      assert_raise(ActiveRecord::RecordNotFound) { Task.find id }
    end

    mc_question_ids.each do |id|
      assert_raise(ActiveRecord::RecordNotFound) { MCQuestion.find id }
    end

    fr_question_ids.each do |id|
      assert_raise(ActiveRecord::RecordNotFound) { FRQuestion.find id }
    end
  end

  test "destroying a production job requires privileged access" do
    # unprivileged user shouldn't be able to destroy a prod job
    e = create :evaluation, :prod => true
    delete :destroy, :id => e.id
    assert_redirected_to evaluation_path(e.id)
    assert_not_nil Evaluation.find e.id
    assert_equal flash[:error], STRINGS[:not_privileged]

    # privileged user should
    login_priv
    delete :destroy, :id => e.id
    assert_redirected_to :controller => :evaluations, :action => :index
    assert_raise(ActiveRecord::RecordNotFound) { Evaluation.find e.id }
  end

  test "random task" do
    # we already test Evaluation#random_task, so just check that is uses that
    # and that it redirects to something valid

    e = create :evaluation_with_tasks
    e.expects(:random_task).returns(e.tasks.first)
    Evaluation.stubs(:find).with(e.id.to_s).returns(e)

    get :random_task, :id => e.id
    assert_redirected_to evaluation_task_path(e, e.tasks.first)
  end

  # This asserts that a method that normally spawns off a job to interact
  # with MTurk requires privilaged access to work with production jobs.
  #
  # protected_method: This is the method that should get called on the
  #                   evaluation when the block is executed by a privileged
  #                   user.
  # block:            This block should send a request to the controller that
  #                   calls protected_method iff the current user is privileged
  def assert_require_priv protected_method, &block
    e = create :evaluation, :prod => true
    Evaluation.stubs(:find).with(e.id.to_s).returns(e)

    # assert that an unprivileged user get an error
    login
    e.expects(protected_method).times(0)
    block.call e
    assert_redirected_to evaluation_path(e)
    assert_equal flash[:error], STRINGS[:not_privileged]

    # assert that a privileged user can do it
    login_priv
    j = Job.create
    e.expects(protected_method).times(1).returns(j)
    block.call e
    assert_redirected_to job_path(j)
  end

  test "submit" do
    e = create :evaluation
    j = Job.create

    e.expects(:submit!).returns(j)
    Evaluation.stubs(:find).with(e.id.to_s).returns(e)

    get :submit, :id => e.id
    assert_redirected_to job_path(j)
  end

  test "submitting a prod job requires privileged access" do
    assert_require_priv(:submit!) do |e|
      get :submit, :id => e.id
    end
  end

  test "purge" do
    e = create :evaluation
    j = Job.create

    e.expects(:purge_from_mturk!).returns(j)
    Evaluation.stubs(:find).with(e.id.to_s).returns(e)

    get :purge, :id => e.id
    assert_redirected_to job_path(j)
  end

  test "purging a prod job requires privileged access" do
    assert_require_priv(:purge_from_mturk!) do |e|
      get :purge, :id => e.id
    end
  end

  test "close" do
    e = create :evaluation
    j = Job.create

    e.expects(:close!).returns(j)
    Evaluation.stubs(:find).with(e.id.to_s).returns(e)

    get :close, :id => e.id
    assert_redirected_to job_path(j)
  end

  test "closing a prod job requires privileged access" do
    assert_require_priv(:close!) do |e|
      get :close, :id => e.id
    end
  end

  test "approve all" do
    e = create :evaluation
    j = Job.create

    e.expects(:approve_all!).returns(j)
    Evaluation.stubs(:find).with(e.id.to_s).returns(e)

    get :approve_all, :id => e.id
    assert_redirected_to job_path(j)
  end

  test "approving all a prod job requires privileged access" do
    assert_require_priv(:approve_all!) do |e|
      get :approve_all, :id => e.id
    end
  end

  test "edit template" do
    e = create :evaluation_with_tasks
    Evaluation.expects(:find).with(e.id.to_s).returns(e)

    get :edit_template, :id => e.id

    assert_equal e, assigns(:evaluation)
    assert_equal ['item1', 'item2', 'tweet', 'metadata1', 'metadata2'].to_set, assigns(:fields).to_set
  end

  test "update template" do
    e = create :evaluation_with_tasks_and_questions, :mc_option_count => 2

    fr1 = e.fr_questions.first
    fr2 = e.fr_questions.second
    mc1 = e.mc_questions.first
    mc1_opt1 = mc1.mc_question_options.first
    mc1_opt2 = mc1.mc_question_options.second
    mc2 = e.mc_questions.second
    mc2_opt1 = mc2.mc_question_options.first
    mc2_opt2 = mc2.mc_question_options.second

    put :update_template, :id => e.id, :evaluation => {
      :metadata => ['data1', 'metadata2'],
      :headers_attributes => {
        '1' => { :order => 3, :content => 'FooHeader' },
        '2' => { :order => 2, :content => 'BarHeader' }
      },
      :texts_attributes => {
        '3' => { :order => 5, :content => 'FooText' },
        '4' => { :order => 0, :content => 'BarText', :_destroy => '1' }
      },
      :components_attributes => {
        '5' => {
          :type => 'user',
          :order => 12,
          :data => {
            :user => {
              :profile_image => { :value => '_nil',      :literal => ''            },
              :name          => { :value => '_nil',      :literal => ''            },
              :username      => { :value => 'item1',     :literal => ''            },
              :bio           => { :value => '_nil',      :literal => ''            },
              :location      => { :value => 'item2',     :literal => ''            },
              :website       => { :value => '_nil',      :literal => ''            },
              :recent_tweets => { :value => '_literal',  :literal => 'foo literal' },
              :retweets      => { :value => '_nil',      :literal => ''            },
              :favorites     => { :value => '_nil',      :literal => ''            }
            },
            # make sure data from other components doesn't interfere
            :user_link => { :username => { :value => 'wrong' } }
          }
        },
        '6' => {
          :type => 'tweet',
          :order => 1,
          :data => { :tweet => { :tweet_id => { :value => 'tweet' } } }
        },
        '7' => {
          :type => 'tweet',
          :order => 7,
          :_destroy => '1',
          :data => { :tweet => { :tweet_id => { :value => 'tweet' } } }
        },
        '8' => {
          :type => 'tweet',
          :order => 11,
          :data => { :tweet => { :tweet_id => { :value => 'data1' } } }
        }
      },
      :fr_questions_attributes => {
        '10' => {:label => 'fr 1', :order => 9, :required => '1', :id => fr1.id.to_s                   },
        '11' => {:label => 'fr 2', :order => 8, :required => '0', :id => fr2.id.to_s, :_destroy => '1' },
        '9'  => {:label => 'fr 3', :order => 6, :required => '0'                                       }
      },
      :mc_questions_attributes => {
        '12' => {
          :label => 'mc 1',
          :order => 4,
          :id => mc1.id,
          :mc_question_options_attributes => {
            '12' => {:label => '1-opt1', :order => 0, :id => mc1_opt1.id.to_s, :_destroy => '1'},
            '13' => {:label => '1-opt3', :order => 1                                           },
            '14' => {:label => '1-opt2', :order => 2, :id => mc1_opt2.id.to_s                  }
          }
        },
        '15' => {
          :label => 'mc 2',
          :order => 10,
          :id => mc2.id,
          :_destroy => '1',
          :mc_question_options_attributes => {
            '16' => { :label => '2-opt1', :order => 0, :id => mc2_opt1.id.to_s },
            '17' => { :label => '2-opt2', :order => 1, :id => mc2_opt2.id.to_s }
          }
        }
      }
    }

    assert_redirected_to evaluation_path(e)
    assert_equal 'Evaluation was successfully updated.', flash[:notice]

    e.reload

    # assert template and metadata were updated correctly
    assert_equal ['data1', 'metadata2'], e.metadata

    new_fr = FRQuestion.last
    new_option = MCQuestionOption.last

    expected_template = [
      {
        :type => 'tweet',
        :order => '1',
        :data => { :tweet_id => { :value => 'tweet' } }
      },
      { :type => :_header, :order => '2',  :content => 'BarHeader' },
      { :type => :_header, :order => '3',  :content => 'FooHeader' },
      { :type => :_mc,     :order => '4',                          },
      { :type => :_text,   :order => '5',  :content => 'FooText'   },
      { :type => :_fr,     :order => '6',                          },
      { :type => :_fr,     :order => '9',                          },
      {
        :type => 'tweet',
        :order => '11',
        :data => { :tweet_id => { :value => 'data1' } }
      },
      {
        :type => 'user',
        :order => '12',
        :data => {
          :profile_image => { :value => '_nil',      :literal => ''            },
          :name          => { :value => '_nil',      :literal => ''            },
          :username      => { :value => 'item1',     :literal => ''            },
          :bio           => { :value => '_nil',      :literal => ''            },
          :location      => { :value => 'item2',     :literal => ''            },
          :website       => { :value => '_nil',      :literal => ''            },
          :recent_tweets => { :value => '_literal',  :literal => 'foo literal' },
          :retweets      => { :value => '_nil',      :literal => ''            },
          :favorites     => { :value => '_nil',      :literal => ''            }
        }
      }
    ].map{|hsh| HashWithIndifferentAccess.new(hsh)}

    assert_equal expected_template, e.template

    # assert FR questions were updated correctly
    assert_equal 2, e.fr_questions.size

    assert_equal 'fr 3', e.fr_questions.first.label
    assert_equal 6, e.fr_questions.first.order
    assert_equal false, e.fr_questions.first.required

    assert_equal 'fr 1', e.fr_questions.second.label
    assert_equal 9, e.fr_questions.second.order
    assert_equal true, e.fr_questions.second.required


    # assert MC questions and options were updated correctly
    assert_equal 1, e.mc_questions.size
    q = e.mc_questions.first
    assert_equal 'mc 1', q.label
    assert_equal 4, q.order
    assert_equal 2, q.mc_question_options.size
    assert_equal '1-opt3', q.mc_question_options.first.label
    assert_equal '1-opt2', q.mc_question_options.second.label
  end
  
  test "original data" do
    eval = create :evaluation

    expected_task_1_data = {
      "foo1" => "bar1",
      "foo2" => "bar2"
    }

    expected_task_2_data = {
      "foo1" => "bar3",
      "foo2" => "bar4"
    }

    eval.add_tasks(parse_json_fixture('data1.json'))
    
    expected_data = [HashWithIndifferentAccess.new({:foo1 => "bar1", :foo2 => "bar2"}),
                     HashWithIndifferentAccess.new({:foo1 => "bar3", :foo2 => "bar4"})]
    get :original_data, :id => eval.id
    assert_equal expected_data, assigns(:data)    

    # test csv

    expected_csv = <<-END_CSV
      foo1,foo2
      bar1,bar2
      bar3,bar4
    END_CSV
    expected_csv = expected_csv.lines.map{|line| line.lstrip}.join

    get :original_data, :format => 'csv', :id => eval.id
    assert_equal expected_csv, response.body

    # test tsv
    expected_tsv = <<-END_TSV
      foo1\tfoo2
      bar1\tbar2
      bar3\tbar4
    END_TSV
    expected_tsv = expected_tsv.lines.map{|line| line.lstrip}.join

    get :original_data, :format => 'tsv', :id => eval.id
    assert_equal expected_tsv, response.body
  end  
end
