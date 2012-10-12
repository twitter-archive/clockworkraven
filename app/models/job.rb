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

require 'thread'

# Represents a job that is executing in Resque.
#
# The background thread can periodically update the job's completion attribute
# to provide status updates on progress -- the job's percent completion should
# always be job.completed / job.total
#
# Attributes
#
# resque_job:   The UUID of the Resque job.
# title:        A title, displayed to Clockwork Raven users
# complete_url: The URL to direct the user to when to job has completed
# back_url:     The URL to direct the user to if they wish to go back to their
#               previous screen while the job executes
class Job < ActiveRecord::Base
  has_one :evaluation

  # Processes <param> using the ThreadPoolProcessor <worker_class>
  def run processor_class, items, options = {}
    options[:items] = items
    self.processor = processor_class
    self.resque_job = processor_class.create(options)
    self.save!
  end

  # Fetches this job's status from Redis
  def status_hash
    if self.resque_job
      return @status_hash if instance_variable_defined? :@status_hash
      @status_hash = Resque::Plugins::Status::Hash.get(self.resque_job)
    else
      nil
    end
  end

  # Returns the name of this job as a symbol (:new, :running, :done, :error, or
  # :killed)
  def status_name
    return :new unless resque_job
    return :done unless status_hash

    case status_hash.status
    when 'queued'
      :new
    when 'completed'
      :done
    when 'failed'
      :error
    when 'killed'
      :killed
    when 'working'
      :running
    else
      :done
    end
  end

  # Returns the percentage completion of this job (between 0 and 100),
  # based on this job's "completed" and "total" properties
  def percentage
    return 100 if status_name == :done
    return 0 if status_name == :new

    status_hash.pct_complete
  end

  # Returns the number of total steps in this job
  def total
    return status_hash.total if status_hash and status_hash.total
    return evaluation.tasks.count if evaluation
    return 1
  end

  # Returns the number of steps this job has compeleted
  def completed
    return total if status_name == :done
    return 0 if status_name == :new
    return status_hash.num || 0
  end

  # If this job's status is :error or :killed, returns a friendly error message
  # with suggestions for what action the user should take.
  #
  # If this job's status is not :error or :killed, returns nil.
  def error
    case status_name
    when :error
      status_hash.message + "\n\n" + processor::KILL_MESSAGE.strip_heredoc
    when :killed
      "Killed.\n\n" + processor::KILL_MESSAGE.strip_heredoc
    else
      nil
    end
  end

  # returns true iff the task has ended (status name is either :done, :failed
  # or :killed)
  def ended?
    return false unless resque_job
    return true unless status_hash

    !status_hash.killable?
  end

  # Asks for this job to be killed.
  def kill!
    return if ended?

    Resque::Plugins::Status::Hash.kill(self.resque_job)
  end

  # Override #processor and #processor= to store a string and load a
  # constant
  def processor
    (self[:processor] || 'Job::ThreadPoolProcessor').constantize
  end
  def processor= new_processor
    self[:processor] = new_processor.name
  end

  # subclass Job::ThreadPoolProcessor to run jobs.
  class ThreadPoolProcessor
    include Resque::Plugins::Status

    # Override this constant to change the name of the job.
    NAME = "Processing"

    # Override this constant to provide a friendly message to isplay to the user
    # if this job terminate in an error or is killed. Provide suggestion for
    # what the user should do.
    KILL_MESSAGE = "Job may have been partially completed"

    # override this to process and item.
    def process item
    end

    # override this to do stuff before processing starts
    def before
    end

    # override this to do stuff after processing ends
    def after
    end

    # use this to increment the completion counter as your job executes.
    def increment_completion incr=1
      @progress_lock.synchronize {
        @current += incr
        at(@current, @total, "At #{@current} of #{@total}")
      }
    end

    # don't override this
    def perform
      @options = options
      @items = options['items']
      @total = @items.length
      @current = 0
      @progress_lock = Mutex.new

      before

      increment_completion 0

      Threading.thread_pool @items do |item|
        process item
        increment_completion
      end

      after
    end
  end
end