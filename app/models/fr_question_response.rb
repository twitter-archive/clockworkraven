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

# Represents an individual response to a free-response question. Associated
# with the free-response question and the TaskResponse, which represents
# the workers entire response.
#
# Attributes
#
# response: the text of the response given by the MTurk user
class FRQuestionResponse < ActiveRecord::Base
  belongs_to :fr_question
  belongs_to :task_response
end