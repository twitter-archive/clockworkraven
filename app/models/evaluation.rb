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

# Represents a HIT, comprised of a number of individual tasks and questions
# asked for each task.
#
# Attributes
#
# name:               The name displayed in Clockwork Raven
# title:              The name displayed on Mechanical Turk
# creator:            The name of the user who created this Evaluation
# email:              The email of the user who created this Evaluation
# desc:               Description shown on MTurk
# payment:            Payment given to workers for tasks, in cents
# keywords:           Comma-separated list of keywords, shown on MTurk
# duration:           Time, in seconds, workers have to complete this task
# lifetime:           Amount of time, in seconds, to leave this task on MTurk
# auto_approve:       Amount of time, in seconds, between when a worker submits
#                     a response and that response is automatically approved
# mturk_hit_type:     The ID of the MTurk HIT Type assigned to this Evaluation
#                     by the API
# status:             The status of this evaluation in its lifecycle (see
#                     Evaluation::STATUS_ID)
# mturk_qualfication: The name of the qualification required of workers. Should
#                     be one of "none", "trusted", or "master".
# note:               Internal note displayed on Clockwork Raven
# prod:               Boolean flag. If true, this evaluation is being run on
#                     the production MTurk system, rather than the sandbox.
# template:           Serialized representation of the template used to
#                     format this evaluation's tasks. See below for format.
# metadata:           Which fields of this evaluation's tasks' data are
#                     metadata. See below for more.
class Evaluation < ActiveRecord::Base
  belongs_to :user
  belongs_to :job

  # we use these fields in the form to create/update Evaluations -- they're
  # not persisted to the database, but giving them accessors/mutators means
  # we can use form helpers
  attr_accessor :data, :replace_data

  # The template this evaluation's tasks are build from. This is an array of
  # hashes where each hash represent an item to be displayed. These items
  # can take 3 forms.
  #
  # Form 1: a block of text or a header
  # {
  #   :type => :_text OR :_header,
  #   :content => <string>
  # }
  #
  # Form 2: a MC or FR question
  # {
  #   :type => :_mc OR :_fr,
  #   :order => <integer>
  # }
  #
  # The order key is the "order" property of the MCQuestion or FRQuestion.
  # The primary function of the key is the set the order in which questions
  # are displayed, but we lookup by this key so we don't need to update the
  # template when we copy an eval.
  #
  # Form 3: a component from app/views/components
  # {
  #   :type => <name of partial in app/views/components>,
  #   :data => {
  #     <key 1> => <data item 1>,
  #     <key 2> => <data item 2>,
  #     ...etc...
  #   }
  # }
  #
  # A data item represents a value that will be given to the partial, as
  # requested in its entry in app/views/components/manifest.yml. It can be
  # nil, a literal string value, or the name of a field (one of the columns
  # in the uploaded data). The format:
  #
  # data item ::= {
  #   :value => :_literal OR :_nil OR <field name>,
  #   :literal => <string> // <- only if :value is :_literal
  # }
  serialize :template, Array

  # Array of strings. These strings are the keys of this evaluation's tasks
  # that will be treated as metadata (not shown to MTurk judges, but included
  # as multiple-choice questions when reviewing the data)
  serialize :metadata, Array

  # status name => status id
  # new: not yet submitted to MTurk
  # submitted: on MTurk, open for judges
  # closed: closed on MTurk
  # approved: all tasks have been approved or rejected
  # purged: removed from MTurk
  STATUS_ID = {
    :new => 0,
    :submitted => 1,
    :closed => 2,
    :approved => 3,
    :purged => 4
  }

  # status id => status name
  STATUS_NAME = STATUS_ID.invert

  # establish associations. establish a stable sort order for questions.
  has_many :tasks, :dependent => :destroy
  has_many :mc_questions, :dependent => :destroy, :order => '`metadata` ASC, `order` ASC'
  has_many :mc_question_options, :through => :mc_questions
  has_many :fr_questions, :dependent => :destroy, :order => '`order` ASC'
  has_many :task_responses, :through => :tasks

  # use nested attributes so we can easily add/modify questions from the
  # evaluation form
  accepts_nested_attributes_for :mc_questions,
                                :allow_destroy => true
  accepts_nested_attributes_for :fr_questions,
                                :allow_destroy => true

  # basic validations
  validates :name, :presence => true, :uniqueness => {:case_sensitive => false}

  validates :desc, :title, :presence => true

  validates :payment, :numericality => { :only_integer => true, :greater_than_or_equal_to => 1}

  validates :status, :numericality => { :only_integer => true,
                                        :greater_than_or_equal_to => 0,
                                        :less_than_or_equal_to => 4 }

  validates :mturk_qualification, :inclusion => { :in => %w(none trusted master) }

  # Creates accessors for time fields that converts between seconds and minutes
  # These fields are accessible through :field_in_minutes
  def self.minutes_accessor(*args)
    args.each do |a|
      class_eval do
        name = a.to_s + "_in_minutes"
        define_method(name) { self[a] / 60 }
        define_method(name + "=") { |min| self[a] = min.to_i * 60 }
      end
    end
  end

  minutes_accessor :duration, :lifetime, :auto_approve

  # Given an array of objects, add a Task to this evaluation for each element
  # of the array and return the corresponding array of Tasks
  #
  # Each element of the array should be a Hash. That Hash will be stored in the
  # Task's "data" property.
  def add_tasks data
    data.map do |item|
      task = self.tasks.build :data => item
      task.save!
      task
    end
  end

  # Adds a single Task to this evaluation and returns that Task
  # data should be one hash, not an array of hashes as in add_tasks
  def add_task data
    add_tasks([data]).first
  end

  # Returns a random task that belongs to this Evaluation
  def random_task
    # special-case this: rand(0) gives a floating point between 0 and 1
    return nil if self.tasks.empty?

    self.tasks.find(:first, :offset => rand(self.tasks.size))
  end

  # Returns the name of the current status as a symbol: :new, :submitted,
  # :closed, :approved, or :purged.
  def status_name
    return STATUS_NAME[self.status]
  end

  # Fetches the number of available results from Mechanical Turk
  def available_results_count
    return MTurkUtils.num_results self
  end

  # Returns the url of the task group associated with this evaluation on
  # mechanical turk
  def mturk_url
    return MTurkUtils.get_hit_url self
  end

  # returns the mturk qualifiaction id for this evaluation's mturk_qualification
  # (which should be "trusted", "master", or "none".) Returns nil if
  # mturk_qualification is "none" or an unrecognized value.
  #
  # note that the qualification type ids are different for production mturk
  # vs sandbox mturk
  def mturk_qualification_type
    if self.mturk_qualification == 'trusted'
      return MTurkUtils.get_trusted_qual_id self.prod?
    elsif self.mturk_qualification == 'master'
      return MTurkUtils.get_master_qual_id self.prod?
    else
      return nil
    end
  end

  # fields to copy when basing an evaluation on another evaluation
  BASED_ON_FIELDS = [:desc, :keywords, :payment, :duration,
                     :lifetime, :auto_approve, :mturk_qualification, :title,
                     :template, :metadata]

  # Copies specific parts of this evaluation. instructions, desc, keywords,
  # payment, duration, lifetime, auto_approve, mturk_qualification, template,
  # metadata and title are copied. name, creator, email, note, and prod are not.
  #
  # Questions associated with this evaluation (and, for MC questions,
  # their options) are copied to the new evaluation by value, not reference.
  #
  # If copy_template is set to true
  def Evaluation.based_on base
    e = Evaluation.new

    # copy fields
    BASED_ON_FIELDS.each do |field|
      e[field] = base[field]
    end

    # copy FR questions
    base.fr_questions.each do |q|
      new_q = e.fr_questions.build(:label => q.label, :order => q.order, :required => q.required)
    end

    # copy MC questions
    base.mc_questions.where(:metadata => false).each do |base_q|
      new_q = e.mc_questions.build(:label => base_q.label, :order => base_q.order)
      base_q.mc_question_options.each do |base_option|
        new_q.mc_question_options.build(:label => base_option.label,
                                        :value => base_option.value,
                                        :order => base_option.order)
      end
    end

    return e
  end

  # Registers this evaluation as a HIT Type on MTurk, then submits all
  # of this evaluation's tasks as HITs. Tasks are submitted in the background.
  # Returns the Job corresponding to submitting the tasks.
  #
  # Sets this Evaluation's status to :submitted on successful completion.
  #
  # If the job fails, it is safe to re-run this method within 24 hours.
  # It will not create duplicate HITs within 24 hours.
  def submit!
    MTurkUtils.register_hit_type self
    run_task_job SubmitProcessor
  end

  # Closes all of this Evluation's Tasks on MTurk and imports the results
  # as TaskResponses. Removes all of this Evaluation's existing TaskResponses.
  # Closing/importing is done in the background. Returns the Job corresponding
  # to closing/importing HITs.
  #
  # Sets this Evaluation's status to :closed upon successful completion.
  #
  # Becuase existing TaskResponses are deleted, it is safe to re-run this
  # method if it fails.
  def close!
    run_task_job CloseProcessor
  end

  # Approves all tasks that haven't already been approved or rejected.
  # Approval is done in the background. Returns the Job corresponding
  # to approving the tasks.
  #
  # Call Evaluation#close! before this method -- tasks cannot be
  # approved until they are closed.
  #
  # Sets the Evaluation's status to :approved upon successful completion.
  def approve_all!
    run_task_job ApproveProcessor
  end

  # Removes the HITs corresponding to this Evaluation's Tasks from
  # Mechanical Turk. Removal is done in the background. Returns the Job
  # corresponding to removing the HITs.
  #
  # Call Evaluation#approve_all! before this method -- tasks cannot
  # be purged until they have been closed and either approved or rejected.
  #
  # Sets this Evaluation's status to :purged upon successful completion.
  def purge_from_mturk!
    run_task_job PurgeProcessor
  end

  # The minimum commission taken by MTurk per HIT, in cents.
  MTURK_COMMISSION_MINIMUM = 0.5

  # Calculates cost: (payment + commmission) * (number of tasks)
  # Commission is 10%, minimum 0.5 cents
  # Returns: total cost, in cents
  def cost
    commission = [self.payment/10.0, MTURK_COMMISSION_MINIMUM].max
    return (self.payment + commission) * tasks.size
  end

  # Mean average amount of time it took workers to complete tasks, in seconds.
  def mean_time
    return 0 if self.task_responses.size == 0
    (self.task_responses.map{|r| r.work_duration}.inject(:+) / self.task_responses.size.to_f)
  end

  # Median amount of time it took workers to complete tasks, in seconds
  def median_time
    return 0 if self.task_responses.size == 0

    durations = self.task_responses.map(&:work_duration).sort
    middle = durations.length / 2
    if (durations.size % 2) == 0
      # even, take mean of middle 2
      return (durations[middle] + durations[middle-1]) / 2.0
    else
      # odd, return middle
      return durations[middle]
    end
  end

  # Effective pay rate, in cents per hour, based on mean time
  # tasks per second * seconds per hour * pay per task = pay per hour
  def mean_pay_rate
    mean = self.mean_time
    return 0 if mean_time == 0
    (1.0/mean) * (60.0*60.0) * self.payment
  end

  # Effective pay rate, in cents per hour, based on median time
  # tasks per second * seconds per hour * pay per task = pay per hour
  def median_pay_rate
    median = self.median_time
    return 0 if median == 0
    (1.0/median) * (60.0*60.0) * self.payment
  end
  
  # Array of the names of the columns in the original data file.
  # For example, ["tweet_id", "username", "score"]
  def original_data_column_names
     if self.tasks.empty? 
       []
     else 
       self.tasks.first.data.keys
     end
  end

  private

  # Runs a Job whose complete_url and back_url point to this evaluation,
  # and whose total number of items is the number of tasks this evaluation has.
  # This Evaluation's status will be set to new_status upon completion, and the
  # job will consist of passing each task in this evaluation to the block
  # in a thread pool.
  #
  # if oncomplete is passed, it will be executed when the job is done, and gets
  # the Job as an argument.
  def run_task_job processor
    # Create a job whose completion and back url point to this evaluation
    url = Rails.application.routes.url_helpers.evaluation_url(self, :only_path => true)
    job = Job.create(:complete_url => url,
                     :back_url => url,
                     :title => processor::NAME)

    job.run processor, self.tasks.map{|t| t.id}, :evaluation_id => id

    self.job = job
    self.save!
    return job
  end


end
