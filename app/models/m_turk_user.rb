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

# Represents a user who has responsed to one of our tasks
#
# Attributes:
#
# trusted: Boolean flag indicating if we've trusted this user
# banned:  Boolean flag indicating if we've banned this user
# prod:    Boolean flag indicating if this is a user from the production
#          mturk server or the sandbox server
class MTurkUser < ActiveRecord::Base
  has_many :task_responses

  # Marks the user as trusted, giving them the qualification needed to work
  # on tasks restricted to trusted users
  def trust!
    MTurkUtils.trust_user self
  end

  # Revokes the trusted user qualification
  def untrust!
    MTurkUtils.untrust_user self
  end

  # Prevents a workers from working on any of our tasks
  def ban!
    MTurkUtils.ban_user self
  end

  # Allows a previously banned user to work on tasks
  def unban!
    MTurkUtils.unban_user self
  end
end