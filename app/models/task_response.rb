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

# Represents a MTurk user's response to a Task.
#
# Attributes
#
# work_duration:    The amount of time, in seconds, between when the MTurk user
#                   accepted the task and when they submitted the task
# mturk_assignment: The ID of the assignment on MTurk
# approved:         Boolean flag indicating if we've explicitly approved this
#                   response
class TaskResponse < ActiveRecord::Base
  belongs_to :task
  belongs_to :m_turk_user
  has_many :mc_question_responses, :dependent => :destroy
  has_many :fr_question_responses, :dependent => :destroy

  validates :work_duration, :presence => true

  # Approves all repsonses to this task on Mechanical Turk
  def approve!
    MTurkUtils.approve self.task
  end

  # Rejects all responses to this task on Mechanical Turk
  def reject!
    MTurkUtils.reject self.task
  end
end