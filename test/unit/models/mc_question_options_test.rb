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

require 'test_helper'

class MCQuestionOptionsTest < ActiveSupport::TestCase
  test "automatically clean values of 0" do
    opt1 = MCQuestionOption.create :label => 'foo', :value => 0
    assert_equal nil, opt1.value

    opt2 = MCQuestionOption.create :label => 'bar', :value => 3
    assert_equal 3, opt2.value
  end
end