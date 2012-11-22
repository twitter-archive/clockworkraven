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

# Represents a Task (HIT) that needs to be completed as part of an evaluation.
#
# Attributes
#
# data:      The array of background information presented to MTurk users when
#            they complete this task
# mturk_hit: The HIT id assigned to this task by the MTurk API
class Task < ActiveRecord::Base
  belongs_to :evaluation
  serialize :data, JSON
  serialize :metadata, JSON
  has_many :task_responses, :dependent => :destroy
  before_validation :add_uuid

  validates :uuid, :presence => true

  # Adds this task's metadata as multiple-choice questions
  # TODO: I'm deprecating this.
  def add_metadata_as_questions
    warn "[DEPRECATION] add_metadata_as_questions is deprecated."
  end

  # Returns an HTML page that presents the task, suitable to be sent to
  # Mechanical Turk
  def render
    TasksController.new.show_string(self)
  end

  # Returns the URL of the page on MTurk where this task can be managed.
  def mturk_url
    MTurkUtils.get_task_url self
  end

  # Adds a UUID to use as the unique request token for mturk.
  def add_uuid
    self.uuid ||= UUIDTools::UUID.timestamp_create().to_s
  end
end