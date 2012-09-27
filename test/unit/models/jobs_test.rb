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
                             with(:job_id => job.id).
                             returns('newuuid')

    job.run Job::ThreadPoolProcessor, [1,2,3]
    job.reload

    assert_equal Job::ThreadPoolProcessor, job.processor
    assert_equal 'newuuid', job.resque_job
    assert_equal 3, job.job_parts.count
    assert_equal [1,2,3], job.job_parts.map(&:data).sort
  end

  test "run with options" do
    job = create :job
    Job::ThreadPoolProcessor.expects(:create).
                             with(:job_id => job.id, :foo => 'bar', :baz => 'bax').
                             returns('newuuid2')

    job.run Job::ThreadPoolProcessor, [1,2,3], :foo => 'bar', :baz => 'bax'
    job.reload

    assert_equal Job::ThreadPoolProcessor, job.processor
    assert_equal 'newuuid2', job.resque_job
    assert_equal 3, job.job_parts.count
    assert_equal [1,2,3], job.job_parts.map(&:data).sort
  end

  test "retry" do
    job = create :job_with_parts, :part_count => 3
    part1, part2, part3 = job.job_parts.all
    part1.status = JobPart::STATUS_ID[:error]
    part1.save!
    part2.status = JobPart::STATUS_ID[:done]
    part2.save!
    part3.status = JobPart::STATUS_ID[:error]
    part3.save!

    Job::ThreadPoolProcessor.expects(:create).
                             with(:job_id => job.id, :a => 10, :b => 20).
                             returns('newuuid3')

    job.retry :a => 10, :b => 20
    [job, part1, part2, part3].each &:reload

    assert_equal Job::ThreadPoolProcessor, job.processor
    assert_equal 'newuuid3', job.resque_job
    assert_equal JobPart::STATUS_ID[:new], part1.status
    assert_equal JobPart::STATUS_ID[:done], part2.status
    assert_equal JobPart::STATUS_ID[:new], part3.status
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

  test "success_percentage" do
    job = create :job
    3.times { create :job_part, :job => job, :status_name => :new }
    2.times { create :job_part, :job => job, :status_name => :done }

    assert_equal 40, job.success_percentage

    job2 = create :job
    assert_equal 0, job2.success_percentage
  end

  test "eror_percentage" do
    job = create :job
    4.times { create :job_part, :job => job, :status_name => :new }
    2.times { create :job_part, :job => job, :status_name => :done }
    4.times { create :job_part, :job => job, :status_name => :error }

    assert_equal 40, job.error_percentage

    job2 = create :job
    assert_equal 0, job2.error_percentage
  end

  test "total, total set" do
    job = create :job_with_parts, :part_count => 12
    assert_equal 12, job.total
  end

  test "completed" do
    job = create :job
    2.times { create :job_part, :job => job, :status_name => :done }
    3.times { create :job_part, :job => job, :status_name => :new }
    assert_equal 2, job.completed
  end

  test "error_count" do
    job = create :job
    2.times { create :job_part, :job => job, :status_name => :done }
    3.times { create :job_part, :job => job, :status_name => :error }
    assert_equal 3, job.error_count
  end

  test "error" do
    job = create :job
    mock_status job, :status => 'failed', :message => 'blah'

    part1 = create :job_part, :job => job, :error => 'err a', :status_name => :error
    part2 = create :job_part, :job => job, :error => 'err b', :status_name => :error

    expected = "blah\n\n" +
               "#{Job::ThreadPoolProcessor::KILL_MESSAGE}\n\n" +
               "Error for part ID #{part1.id}: err a\n\n" +
               "Error for part ID #{part2.id}: err b"

    assert_equal expected, job.error
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
      job = create :job_with_parts

      processor = Job::ThreadPoolProcessor.new uuid, 'job_id' => job

      tpp_sequence = sequence 'tpp sequence'

      processor.expects(:before).in_sequence(tpp_sequence)
      job.job_parts.each do |part|
        processor.expects(:process).with(part.data).in_sequence(tpp_sequence)
      end
      processor.expects(:after).in_sequence(tpp_sequence)

      processor.perform
    end
  end

  module TestModule
    module Foo
    end
  end
end