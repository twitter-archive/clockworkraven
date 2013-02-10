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

# Utility methods for interacting with Mechanical Turk
module MTurkUtils
  # Basic structure of the XML structure for an HTML question.
  HTML_QUESTION_XML = <<-END_XML
    <HTMLQuestion xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2011-11-11/HTMLQuestion.xsd">
      <HTMLContent><![CDATA[
        %<content>s
        ]]>
      </HTMLContent>
      <FrameHeight>%<height>s</FrameHeight>
    </HTMLQuestion>
  END_XML

  class << self
    # Reloads the configuration from MTURK_CONFIG
    def init
      init_prod
      init_sandbox
    end

    # Reloads the configuration from config/mturk_prod.yml
    def init_prod
      @mturk_prod = Amazon::WebServices::MechanicalTurkRequester.new(
        :AWSAccessKeyId => MTURK_CONFIG[:access_key_id],
        :AWSAccessKey   => MTURK_CONFIG[:access_key],
        :SkipSSLCheck   => MTURK_CONFIG[:ssl_verify] == false || MTURK_CONFIG[:ssl_verify] == 'false' || MTURK_CONFIG[:ssl_verify] == 'none',
        :Host           => 'Prod'
      )
    end

    # Reloads the configuration from config/mturk_sandbox.yml
    def init_sandbox
      @mturk_sandbox = Amazon::WebServices::MechanicalTurkRequester.new(
        :AWSAccessKeyId => MTURK_CONFIG[:access_key_id],
        :AWSAccessKey   => MTURK_CONFIG[:access_key],
        :SkipSSLCheck   => MTURK_CONFIG[:ssl_verify] == false || MTURK_CONFIG[:ssl_verify] == 'false' || MTURK_CONFIG[:ssl_verify] == 'none',
        :Host           => 'Sandbox'
      )
    end

    private

    # Calls init_prod and init_sandbox if the configs haven't already been
    # loaded
    def init_if_needed
      init_prod if @mturk_prod.nil?
      init_sandbox if @mturk_sandbox.nil?
    end

    public

    # Returns the url of a HIT group, given the associated Evaluation.
    def get_hit_url eval
      if !eval.prod?
        # Sandbox Url
        "http://workersandbox.mturk.com/mturk/preview?groupId=#{eval.mturk_hit_type}"
      else
        # Production Url
        "http://mturk.com/mturk/preview?groupId=#{eval.mturk_hit_type}"
      end
    end

    # Returns the URL to manage a given Task.
    def get_task_url task
      hit_id = task.mturk_hit
      if !task.evaluation.prod?
        # Sandbox Url
        "http://requestersandbox.mturk.com/mturk/manageHIT?HITId=#{hit_id}"
      else
        # Production Url
        "http://requester.mturk.com/mturk/manageHIT?HITId=#{hit_id}"
      end
    end

    # Returns the id of the "trusted workers" qualification. If prod is true
    # the id is for the production mturk service, else it is for the
    # sandbox mturk service.
    def get_trusted_qual_id prod
      init_if_needed
      if !prod
        # Sandbox id
        MTURK_CONFIG[:qualifications][:trusted][:sandbox]
      else
        # Production id
        MTURK_CONFIG[:qualifications][:trusted][:prod]
      end
    end

    # Returns the id of the "categorization masters" qualification. If prod is
    # true the id is for the production mturk service, else it is for the
    # sandbox mturk service.
    def get_master_qual_id prod
      init_if_needed
      if !prod
        # Sandbox id
        MTURK_CONFIG[:qualifications][:master][:sandbox]
      else
        # Production id
        MTURK_CONFIG[:qualifications][:master][:prod]
      end
    end

    private

    # Given an HTML page and a frame height, returns the XML that should be
    # sent to mechanical turk for an HTMLQuestion.
    def build_question_xml content, frame_height=400
      HTML_QUESTION_XML % {:content => content, :height => frame_height}
    end

    public

    # Submits a Task to mechanical turk. Registers the task's Evaluation as
    # a hit type if needed. Updates the task's mturk_hit property upon
    # successful completion.
    def submit_task task
      eval = task.evaluation
      if eval.mturk_hit_type.blank?
        register_hit_type eval
      end

      props = {
        :HITTypeId => eval.mturk_hit_type,
        :Question => build_question_xml(task.render),
        :LifetimeInSeconds => eval.lifetime,
        :MaxAssignments => eval.num_judges_per_task,
        :UniqueRequestToken => task.uuid
      }

      result = mturk_run do
        mturk(task.evaluation).createHIT(props)
      end
      if result
        task.mturk_hit = result[:HITId]
        task.save!
      end
    end

    # Registers an Evaluation as a HIT type on mechanical turk. Updates the
    # evaluation's mturk_hit_type property upon successful completion.
    def register_hit_type eval
      props = {
        :Title => eval.title,
        :Description => eval.desc + " (CR ID: #{eval.id})",
        :Reward => { :Amount => (eval.payment / 100.0), :CurrencyCode => 'USD' },
        :AssignmentDurationInSeconds => eval.duration,
        :Keywords => eval.keywords,
        :AutoApprovalDelayInSeconds => eval.auto_approve
      }

      if eval.mturk_qualification_type != nil
        props[:QualificationRequirement] = [{
          :QualificationTypeId => eval.mturk_qualification_type,
          :Comparator => 'Exists',
          :RequiredToPreview => true
        }]
      end

      result = mturk(eval).registerHITType(props)

      eval.mturk_hit_type = result[:HITTypeId]
      eval.save!
    end

    # Returns the number of results submitted by mturk judges for a particular
    # Evaluation.
    def num_results eval
      mturk(eval).getReviewableHITs(:HITTypeId => eval.mturk_hit_type)[:TotalNumResults]
    end

    # Imports responses to the given Task as a TaskResult.
    def fetch_results task
      hit_id = task.mturk_hit
      return unless hit_id

      assignments_metadata = mturk_run{mturk(task.evaluation).getAssignmentsForHIT :HITId => hit_id}

      # return if we don't have any responses
      if assignments_metadata.nil? or assignments_metadata[:Assignment].nil?
        Rails.logger.warn("[fetch_results] No responses for task #{task.id}")
        return
      end

      assignments = assignments_metadata[:Assignment]
      unless assignments.kind_of? Array
        # If there's only one assignment, we get a single hash rather than a bunch
        # of hashes wrapped in an array. We wrap this hash in an array for
        # consistency.
        assignments = [assignments]
      end

      assignments.each do |assignment|
        process_assignment(task, assignment)
      end
    end

    # Used for importing responses to individual assignments of the given Task. TODO: make private.
    def process_assignment task, assignment
      answers = Hash.from_xml(assignment[:Answer])["QuestionFormAnswers"]["Answer"]

      unless answers.kind_of? Array
        # If there's only one question, we get a single hash rather than a bunch
        # of hashes wrapped in an array. We wrap this hash in an array for
        # consistency.
        answers = [answers]
      end

      worker_id = assignment[:WorkerId]
      time = assignment[:SubmitTime] - assignment[:AcceptTime]

      response = TaskResponse.new
      response.task = task
      response.m_turk_user = MTurkUser.find_or_create_by_id_and_prod worker_id, task.evaluation.prod
      response.work_duration = time

      # import answer data
      answers.each do |answer|
        # question identifiers are in the format "type:id" where type is
        # "fr" or "mc" and id is the id of the FRQuestion or MCQuestion.

        # If no response was submitted, we get a result in the form
        # ["QuestionIdentifier", "mc:177"], which we need to special-case

        if answer.kind_of? Array
          Rails.logger.warn("[fetch_results] Got no response for MCQuestion #{answer.last} in task #{task.id}")
          next
        end

        question_type, question_id = answer["QuestionIdentifier"].split(':')
        answer_content = answer["FreeText"]

        if question_type == "fr"
          # free-response question
          begin
            question = FRQuestion.find question_id.to_i
          rescue ActiveRecord::RecordNotFound
            Rails.logger.warn("[fetch_results] Could not find FRQuestion #{question_id}")
            next
          end

          question_response = response.fr_question_responses.build

          if answer_content.blank?
            answer_content = "No response given"
          end

          question_response.response = answer_content
          question_response.fr_question = question
        elsif question_type == "mc"
          # multiple-choice question
          begin
            option = MCQuestionOption.find answer_content.to_i
          rescue ActiveRecord::RecordNotFound
            Rails.logger.warn("[fetch_results] Could not find MCQuestion #{answer_content}")
            next
          end

          next if option.nil?

          question_response = response.mc_question_responses.build
          question_response.mc_question_option = option
        end
      end

      puts response.inspect
      response.save!
    end

    # Given an assignment returned from getAssignmentsForHIT, parses the answers from the
    # assignment (represented as an XML string) into a readable string-to-string hash where the
    # key is the question label and the value is the answer.
    #
    # TODO: Refactor assignment-related utility methods into a module that wraps the assignment
    # type. This method seems too specific to assignments to be in this module.
    # TODO: Refactor fetch_results to use this method/eliminate duplicate code. Maybe create
    # another method that does what this method does but includes meta-info that fetch_results
    # needs and then this method can filter it.
    def assignment_results_to_hash assignment
      return {} if assignment.nil?

      answers = Hash.from_xml(assignment[:Answer])["QuestionFormAnswers"]["Answer"]
      answers = [answers] if not answers.kind_of? Array

      answers.each_with_object({}) do |answer, curr_answers_hash|
        question_type, question_id = answer['QuestionIdentifier'].split(':')
        answer_content = answer['FreeText']

        if question_type == 'fr'
          fr_question = FRQuestion.find_by_id(question_id.to_i)
          next if fr_question.nil?
          answer_content = 'No response given' if answer_content.blank?
          answer_key, answer_value = fr_question.label, answer_content
        elsif question_type == 'mc'
          mc_question_option = MCQuestionOption.find_by_id(answer_content.to_i)
          next if mc_question_option.nil? or mc_question_option.mc_question.nil?
          answer_key, answer_value = mc_question_option.mc_question.label, mc_question_option.label
        end

        next if answer_key.nil?
        answer_value = "No response given" if answer_value.nil?
        curr_answers_hash[answer_key] = answer_value
      end
    end

    # Gets the assignment (contains completion status, answers, other info) for a given Task
    # More info on the assignment data structure here:
    # http://docs.amazonwebservices.com/AWSMechTurk/2007-06-21/AWSMechanicalTurkRequester/ApiReference_AssignmentDataStructureArticle.html
    def fetch_assignment_for_task task
      mturk(task.evaluation).getAssignmentsForHIT(:HITId => task.mturk_hit)[:Assignment]
    end

    # Expires a task, so mturk works can no longer complete it
    def force_expire task
      hit_id = task.mturk_hit
      return unless hit_id

      begin
        mturk_run{mturk(task.evaluation).forceExpireHIT( :HITId => hit_id )}
      rescue => e
        # ignore mturk complaining about the task already being expired
        raise e unless e.message.include? 'AWS.MechanicalTurk'
      end
    end

    # Approves all responses submitted for a given Task,  and then updates
    # the approved property of the task.
    def approve task
      return unless task.mturk_hit
      approve_remaining_assignments task

      return unless task.task_responses

      task.task_responses.each do |task_response|
        if task_response.approved.nil?
          task_response.approved = true
          task_response.save!
        end
      end
    end

    # Rejects all responses submitted for a given task, and then updates
    # the approved property of the task.
    def reject task
      return unless task.mturk_hit
      reject_remaining_assignments task

      return unless task.task_responses

      task.task_responses.each do |task_response|
        if task_response.approved.nil?
          task_response.approved = false
          task_response.save!
        end
      end
    end

    private

    # Approves all responses submitted to a given Task
    def approve_remaining_assignments task
      hit_id = task.mturk_hit
      client = mturk(task.evaluation)
      return unless hit_id

      mturk_run do
        client.getAssignmentsForHITAll( :HITId => hit_id ).each do |assignment|
          if assignment[:AssignmentStatus] == 'Submitted'
            # "Submitted" means we haven't approved or denied yet
            client.approveAssignment :AssignmentId => assignment[:AssignmentId]
          end
        end
      end
    end

    # Rejects all responses submitted to a given task
    def reject_remaining_assignments task
      hit_id = task.mturk_hit
      client = mturk(task.evaluation)
      return unless hit_id

      count = 0
      mturk_run do
        client.getAssignmentsForHITAll( :HITId => hit_id ).each do |assignment|
          client.rejectAssignment :AssignmentId => assignment[:AssignmentId] if assignment[:AssignmentStatus] == 'Submitted'
          count += 1
        end
      end

      return count
    end

    public

    # Removes a task from MTurk. Fails unless all responses for the task
    # have been approved.
    def dispose task
      hit_id = task.mturk_hit
      return unless hit_id
      mturk_run{mturk(task.evaluation).disposeHIT( :HITId => hit_id )}
    end

    # Bans a user from responding to any of our HITs. Updates the user's
    # banned property.
    def ban_user user
      mturk(user).blockWorker :WorkerId => user.id, :Reason => 'Blocked from Clockwork Raven'
      user.banned = true
      user.save!
    end

    # Unbans a previously banned user. Updates the user's banned property.
    def unban_user user
      mturk(user).unblockWorker :WorkerId => user.id
      user.banned = false
      user.save!
    end

    # Adds a user to the "trusted workers" group. Updates the user's trusted
    # property
    def trust_user user
      mturk(user).assignQualification :WorkerId => user.id,
                                      :QualificationTypeId => get_trusted_qual_id(user.prod?)

      user.trusted = true
      user.save!
    end

    # Removes a user from the "trusted workers" group. Updates the user's
    # trusted property.
    def untrust_user user
      begin
        mturk(user).revokeQualification :SubjectId => user.id,
                                        :QualificationTypeId => get_trusted_qual_id(user.prod?)
      rescue => e
        # ignore invalid qualification state; it just means we've already
        # untrusted this user.
        raise e unless e.message.include? 'AWS.MechanicalTurk.InvalidQualificationState'
      end

      user.trusted = false
      user.save!
    end

    SYNC_USERS_PAGE_SIZE = 50
    # Synchronizes the list of trusted and banned users. This should be called
    # if users are banned/unbanned or added/removed from trusted users
    # via something other than Clockwork Raven.
    def sync_users
      init_if_needed

      # get rid of existing lists
      MTurkUser.where('prod = 1 AND ((banned = 1) OR (trusted = 1))').each do |u|
        u.banned = 0
        u.trusted = 0
        u.save!
      end

      # load in trusted users
      trusted = []
      page_num = 1

      # loop to load all pages
      loop do
        page = @mturk_prod.getQualificationsForQualificationType(
          :QualificationTypeId => MTurkUtils.get_trusted_qual_id(true),
          :PageSize => SYNC_USERS_PAGE_SIZE,
          :PageNumber => page_num
        )

        if page[:Qualification].kind_of? Array
          trusted += page[:Qualification].map{|h| h[:SubjectId]}
        else
          trusted.push page[:Qualification][:SubjectId]
        end

        break if (page[:PageNumber] * SYNC_USERS_PAGE_SIZE) > page[:TotalNumResults]

        page_num += 1
      end

      puts "Trusting #{trusted.length} users"

      trusted.each do |user_id|
        user = MTurkUser.find_or_create_by_id(user_id)
        user.trusted = 1
        user.save!
      end

      # load in banned users
      banned = []
      page_num = 1

      # loop to load all pages
      loop do
        page = @mturk_prod.getBlockedWorkers(
          :PageSize => SYNC_USERS_PAGE_SIZE,
          :PageNumber => page_num
        )

        if page[:WorkerBlock].kind_of? Array
          banned += page[:WorkerBlock].map{|h| h[:WorkerId]}
        else
          banned.push page[:WorkerBlock][:WorkerId]
        end

        break if (page[:PageNumber] * SYNC_USERS_PAGE_SIZE) > page[:TotalNumResults]

        page_num += 1
      end

      puts "Banning #{banned.length} users"

      banned.each do |user_id|
        user = MTurkUser.find_or_create_by_id(user_id)
        user.banned = 1
        user.save!
      end
    end

    # runs the given block.
    # if it fails, retries up to three times.
    # will silently ignore ValidationExceptions and throttling after
    # 3 retries
    def mturk_run &block
      init_if_needed
      retries = 0

      begin
        result = block.call
      rescue => e
        if e.message.include? 'AWS.MechanicalTurk.HITAlreadyExists'
          # it's a repeat submit, skip
          return
        else
          # retry a few times
          retries += 1
          if retries <= 3
            retry
          else
            # we're out of retry attempts.
            raise e
          end
        end
      end

      return result
    end

    # gets the sanddbox or production client, based on the Evaluation or
    # MTurkUser.
    def mturk eval_or_user
      init_if_needed
      if eval_or_user.prod?
        return @mturk_prod
      else
        return @mturk_sandbox
      end
    end
  end
end
