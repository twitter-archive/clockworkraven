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

require 'json'
require 'open-uri'

module ComponentsHelper
  # returns the username (without @symbol) of the given user
  def twitter_username(user_id)
    user_json(user_id)["screen_name"]
  end

  private

  def user_json(user_id)
    JSON.parse(open("https://twitter.com/users/#{user_id}.json").read)
  end
end