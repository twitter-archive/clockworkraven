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
  has_many :job_parts

  # Processes <param> using the ThreadPoolProcessor <worker_class>
  def run processor_class, items, options = {}
    # create a JobPart for each item
    parts = items.map do |item|
      [self.id, YAML.dump(item)]
    end

    JobPart.import ['job_id', 'data'], parts

    options[:job_id] = self.id
    self.processor = processor_class
    self.resque_job = processor_class.create(options)
    self.save!
  end

  # Re-runs failed job parts
  def retry options = {}
    self.job_parts.
         where(:status => JobPart::STATUS_ID[:error]).
         update_all(:status => JobPart::STATUS_ID[:new])

    options[:job_id] = self.id
    self.resque_job = self.processor.create(options)
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

  # Returns the percentage of this Job's JobParts that have completed
  # successfully (between 1 and 100)
  def success_percentage
    return 0 if total == 0
    (completed*100.0) / total
  end

  # Returns the percentage of this Job's JobParts that have failed (between 1
  # and 100)
  def error_percentage
    return 0 if total == 0
    (error_count*100.0) / total
  end

  # Returns the number of total steps in this job
  def total
    job_parts.size
  end

  # Returns the number of steps this job has compeleted
  def completed
    job_parts.where(:status => JobPart::STATUS_ID[:done]).count
  end

  # Returns the number of steps that have thrown errors
  def error_count
    job_parts.where(:status => JobPart::STATUS_ID[:error]).count
  end

  # Return true iff the job has ended but parts failed
  def parts_failed?
    ended? and (completed != total)
  end


  # If this job's status is :error or :killed, returns a friendly error message
  # with suggestions for what action the user should take.
  #
  # If any parts of this job have failed, returns the errors from those
  # parts.
  #
  # Else, returns nil.
  def error
    error_parts = []

    case status_name
    when :error
      error_parts.push status_hash.message
      error_parts.push processor::KILL_MESSAGE.strip_heredoc
    when :killed
      error_parts.push 'Killed.'
      error_parts.push processor::KILL_MESSAGE.strip_heredoc
    end

    if error_count > 0
      error_parts += job_parts.where(:status => JobPart::STATUS_ID[:error]).map{ |part|
        "Error for part ID #{part.id}: #{part.error}"
      }
    end

    if error_parts.empty?
      nil
    else
      error_parts.join "\n\n"
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
    KILL_MESSAGE = "Job may have been partially completed."

    # Number of retries per job
    RETRY_COUNT = 3

    # override this to process and item.
    def process item
    end

    # override this to do stuff before processing starts
    def before
    end

    # override this to do stuff after processing ends
    def after
    end

    # don't override this
    def perform
      @options = options
      job = Job.find(options['job_id'])
      @job_parts = job.job_parts.where(:status => 0)
      @progress_lock = Mutex.new

      before

      Threading.thread_pool @job_parts do |job_part|
        safe_process job_part
      end

      after
    end

    private

    # calls #process, with retries and auto-reconnect
    def safe_process job_part_id
      job_part = JobPart.find(job_part_id)
      data = job_part.data
      retries = RETRY_COUNT
      begin
        process data
        job_part.status = JobPart::STATUS_ID[:done]
        job_part.save!
      rescue Resque::Plugins::Status::Killed => e
        # don't retry if we get forcibly killed
        raise e
      rescue => e
        # TODO: reconnect if table not found

        # for any other error, retry if we have retries left.
        Rails.logger.warn("Got an error in thread pool. Retries: #{retries}.\n#{e.inspect}")
        if retries > 1
          retries -= 1
          retry
        else
          job_part.status = JobPart::STATUS_ID[:error]
          job_part.error = "#{e}\n#{e.backtrace.join("\n")}"
          job_part.save!
        end
      end
    end
  end
end