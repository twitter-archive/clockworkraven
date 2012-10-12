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
require 'thread'
require 'ostruct'

class JobsTest < ActiveSupport::TestCase

  test "run without options" do
    job = create :job
    Job::ThreadPoolProcessor.expects(:create).
                             with(:items => [1,2,3]).
                             returns('newuuid')

    job.run Job::ThreadPoolProcessor, [1,2,3]
    job.reload

    assert_equal Job::ThreadPoolProcessor, job.processor
    assert_equal 'newuuid', job.resque_job
  end

  test "run with options" do
    job = create :job
    Job::ThreadPoolProcessor.expects(:create).
                             with(:items => [1,2,3], :foo => 'bar', :baz => 'bax').
                             returns('newuuid2')

    job.run Job::ThreadPoolProcessor, [1,2,3], :foo => 'bar', :baz => 'bax'
    job.reload

    assert_equal Job::ThreadPoolProcessor, job.processor
    assert_equal 'newuuid2', job.resque_job
  end

  test "status_hash, resque_job present" do
    job = create :job
    mock_status job, :a => 1

    assert_equal(1, job.status_hash.a)

    # call #status_hash again to make sure we're caching and not hitting Redis
    # again -- the expects() above will fall if it gets a second invokation.
    assert_equal(1, job.status_hash.a)
  end

  test "status_hash, resque_job not present" do
    job = create :unsubmitted_job
    Resque::Plugins::Status::Hash.expects(:get).times(0)
    assert_equal nil, job.status_hash
  end

  test "status_name, resque_job present" do
    statuses = {'queued' => :new,    'completed' => :done, 'failed' => :error,
                'killed' => :killed, 'working' => :running}

    statuses.each do |status, status_name|
      job = create :job
      mock_status job, :status => status
      assert_equal status_name, job.status_name
    end
  end

  test "status_name, resque_job absent" do
    job = create :unsubmitted_job
    assert_equal :new, job.status_name
  end

  test "status_name, cant find resque_job" do
    job = create :job
    mock_status job, nil
    assert_equal :done, job.status_name
  end

  test "percentage" do
    job = create :job
    mock_status job, :pct_complete => 42, :status => 'working'
    assert_equal 42, job.percentage
  end

  test "percentage, resque_job absent" do
    job = create :unsubmitted_job
    assert_equal 0, job.percentage
  end

  test "percentage, cant find resque_job" do
    job = create :job
    mock_status job, nil
    assert_equal 100, job.percentage
  end

  test "total, total set" do
    job = create :job
    mock_status job, :total => 12
    assert_equal 12, job.total
  end

  test "total, total not set" do
    job = create :job
    mock_status job, {}
    evaluation = create :evaluation_with_tasks, :task_count => 17, :job => job

    assert_equal 17, job.total
  end

  test "total, orphan job" do
    job = create :job
    mock_status job, {}
    assert_equal 1, job.total
  end

  test "completed, num set" do
    job = create :job
    mock_status job, :num => 10, :status => 'working'
    assert_equal 10, job.completed
  end

  test "completed, num not set" do
    job = create :job
    mock_status job, :total => 20, :num => nil, :status => 'completed'
    assert_equal 20, job.completed
  end

  test "completed, cant find resque_job" do
    job = create :job
    mock_status job, nil
    assert_equal 1, job.completed
  end

  test "completed, resque job not set" do
    job = create :unsubmitted_job
    assert_equal 0, job.completed
  end

  test "error, job with error" do
    job = create :job, :processor => Job::ThreadPoolProcessor
    mock_status job, :message => 'An error!', :status => 'failed'
    assert_equal "An error!\n\nJob may have been partially completed", job.error
  end

  test "error, killed job" do
    job = create :job, :processor => Job::ThreadPoolProcessor
    mock_status job, :message => 'An error!', :status => 'killed'
    assert_equal "Killed.\n\nJob may have been partially completed", job.error
  end

  test "error, running job" do
    job = create :job
    mock_status job, :status => 'working'
    assert_nil job.error
  end

  test "kill!" do
    job = create :job
    mock_status job, :status => 'working', :killable? => true
    Resque::Plugins::Status::Hash.expects(:kill).with(job.resque_job)
    job.kill!
  end

  test "kill!, non-ended job" do
    job = create :job
    Resque::Plugins::Status::Hash.expects(:kill).times(0)
    mock_status job, :status => 'completed', :killable? => false
    job.kill!
  end

  test "processor" do
    job = create :job
    job[:processor] = "JobsTest::TestModule::Foo"
    assert_equal TestModule::Foo, job.processor
  end

  test "processor default" do
    job = create :job
    assert_equal Job::ThreadPoolProcessor, job.processor
  end

  test "processor=" do
    job = create :job
    job.processor = TestModule::Foo
    assert_equal job[:processor], "JobsTest::TestModule::Foo"
  end

  test "ThreadPoolProcessor" do
    without_threading do
      uuid = generate :resque_uuid
      processor = Job::ThreadPoolProcessor.new uuid, 'items' => ['first', 'second']

      tpp_sequence = sequence 'tpp sequence'

      processor.expects(:before)                         .in_sequence(tpp_sequence)
      processor.expects(:at)     .with(0, 2, "At 0 of 2").in_sequence(tpp_sequence)
      processor.expects(:process).with('first')          .in_sequence(tpp_sequence)
      processor.expects(:at)     .with(1, 2, "At 1 of 2").in_sequence(tpp_sequence)
      processor.expects(:process).with('second')         .in_sequence(tpp_sequence)
      processor.expects(:at)     .with(2, 2, "At 2 of 2").in_sequence(tpp_sequence)
      processor.expects(:after)                          .in_sequence(tpp_sequence)

      processor.perform
    end
  end

  module TestModule
    module Foo
    end
  end
end