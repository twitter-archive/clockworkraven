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

# Free-response question. Associated with a particular evaluation.
#
# Attributes
#
# label: The question asked to MTurk users
class FRQuestion < ActiveRecord::Base
  validates :label, :presence => true

  belongs_to :evaluation
  has_many :fr_question_responses, :dependent => :destroy
end