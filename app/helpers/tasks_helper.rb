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

module TasksHelper
  # performs interpolation of {{field}} substrings, substituting in the value
  # from the data hash
  def interpolate string, data
    data.each do |key, value|
      string = string.gsub "{{#{key}}}", h(value)
    end
    string.html_safe
  end

  # Renders text as markdown
  def markdown string
    RDiscount.new(string).to_html.html_safe
  end

  # resolves data items, which can be literals, fields, or nils, to the
  # appropriate string. Fields are looked up in the fields hash
  def resolve_data data, fields
    resolved = {}
    data.each do |key, item|
      case item[:value]
      when '_literal'
        resolved[key] = item[:literal]
      when '_nil'
        resolved[key] = nil
      else
        resolved[key] = fields[item[:value]]
      end
    end
    resolved
  end
end