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

module DOMTestHelper
  # asserts that the two HTML string are equivalent, ignoring propery ordering,
  # repeated whitespace, and whitespace between tags
  def assert_dom_equiv expected, actual, msg = nil
    assert_dom_equal compact_whitespace(expected), compact_whitespace(actual), msg
  end

  # asserts that the given HTML string contains the given fragment, ignoring
  # repeated whitespace and whitespace between tags.
  #
  # <document> defaults to response.body
  def assert_html_includes fragment, document = nil, msg = nil
    msg = "Expected fragment #{fragment} in document #{document}"
    document ||= response.body
    assert compact_whitespace(document).include?(compact_whitespace(fragment)), msg
  end

  private

  # compact repeated whitespace into a single space, remove whitespace
  # between tags, and strip leading and trailing whitespace
  def compact_whitespace s
    s.gsub(/\s+/, ' ').gsub(/>\s</, '><').strip
  end
end