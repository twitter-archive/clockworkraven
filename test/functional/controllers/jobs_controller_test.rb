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
require 'ostruct'

class JobsControllerTest < ActionController::TestCase
  setup do
    login
  end

  teardown do
    logout
  end

  test "index" do
    # remove existing jobs left over from other tests
    Job.all.each{|job| job.destroy}

    # create two jobs
    job1 = create :job
    job2 = create :job

    get :index

    # check that the controller responded correctly
    assert_response :success
    assert_equal 2, assigns(:jobs).length
    assert_equal job2, assigns(:jobs).first
    assert_equal job1, assigns(:jobs).second
  end

  test "index pagination" do
    # remove existing jobs left over from other tests
    Job.all.each{|job| job.destroy}

    # make 12 jobs
    jobs = (0..11).map{ create :job }

    # page 1 should be eval[11] through eval[2]
    get :index
    assert_response :success
    assert_equal jobs[2..11].reverse, assigns(:jobs)

    get :index, :page => 1
    assert_response :success
    assert_equal jobs[2..11].reverse, assigns(:jobs)

    # page 2 should be eval[1] and eval[0]
    get :index, :page => 2
    assert_response :success
    assert_equal jobs[0..1].reverse, assigns(:jobs)
  end

  test "show" do
    # create two jobs
    job1 = create :job
    job2 = create :job

    # check that we can show them
    get :show, :id => job1.id
    assert_response :success
    assert_equal job1, assigns(:job)

    get :show, :id => job2.id
    assert_response :success
    assert_equal job2, assigns(:job)
  end

  test "show json" do
    job = create :job, :title        => 'FooJob',
                       :complete_url => 'http://foo.com/bar',
                       :back_url     => 'http://foo.com/baz'

    # mock out the stuff we normally read from Resque
    mock_status job, :status       => 'working',
                     :pct_complete => 75,
                     :total        => 4,
                     :num          => 3,
                     :killable?    => true

    response = get :show, :id => job.id, :format => 'json'

    # check that properties were reported correctly
    response = JSON.parse(response.body)
    assert_equal 'FooJob',             response['title']
    assert_equal 'http://foo.com/bar', response['complete_url']
    assert_equal 'http://foo.com/baz', response['back_url']
    assert_equal 'running',            response['status_name']
    assert_equal 75,                   response['percentage']
    assert_equal 4,                    response['total']
    assert_equal 3,                    response['completed']
    assert_equal false,                response['ended?']
  end

  test "kill" do
    job = create :job

    Job.stubs(:find).with(job.id.to_s).returns(job)
    job.expects(:kill!)

    post :kill, :id => job.id

    assert_redirected_to job_path(job)
  end
end