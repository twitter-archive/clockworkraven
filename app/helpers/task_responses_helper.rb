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

module TaskResponsesHelper
  # "Approved", "Rejected", or "Undecided" based on the approval status
  # of the TaskResponse
  def task_response_status_name response
    case response.approved
    when nil
      "Undecided"
    when true
      "Approved"
    when false
      "Rejected"
    end
  end
end