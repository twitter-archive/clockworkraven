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

module ViewTestHelper
  # inverse of assert_select
  def assert_select_none selector
    assert css_select(selector).empty?,
           "Selector \"#{selector}\" returned results, expected no results"
  end

  # asserts that the given selector matches at least 1 element, and that none
  # of the matched elements have "display: none;"
  def assert_visible selector
    assert_select selector do
      assert_select '[style*="display: none;"]', false
    end
  end

  # assets that the given selector matches at least 1 elements, and that all
  # of the matched elements have "display: none;"
  def assert_hidden selector
    assert_select selector do
      assert_select '[style*="display: none;"]'
    end
  end
end