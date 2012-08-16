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

# Multiple-choice question for a particular evaluation.
#
# Attributes
#
# label:    The question to ask the MTurk judge
# metadata: Boolean flag indicating whether this is a "virtual" question that
#           was created from the metadata in the input data
class MCQuestion < ActiveRecord::Base
  belongs_to :evaluation

  has_many :mc_question_options, :dependent => :destroy, :order => '`order` ASC'

  validates :label, :presence => true

  accepts_nested_attributes_for :mc_question_options,
                                :reject_if => lambda { |a| a[:label].blank? },
                                :allow_destroy => true
  def has_values?
    return self.mc_question_options.where('value IS NOT NULL').count > 0
  end
end