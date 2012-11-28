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

# An option for a particular multiple-choice question.
#
# Attributes
#
# label: The name of this option
class MCQuestionOption < ActiveRecord::Base
  before_save :clean_value

  belongs_to :mc_question
  has_and_belongs_to_many :mc_question_responses

  validates :label, :presence => true

  # value of 0 is the same as no value
  def clean_value
    if self.value == 0
      self.value = nil
    end
  end
end