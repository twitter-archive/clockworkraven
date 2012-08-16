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

class MCQuestionTest < ActiveSupport::TestCase
  test "has values?" do
    q = create :mc_question_with_options, :options_have_values => false
    assert !q.has_values?, 'has_values? returned true for question without values'

    q = create :mc_question_with_options, :options_have_values => true
    assert q.has_values?, 'has_values? returned false for question with values'

    q = create :mc_question_with_options, :options_have_values => false
    opt = q.mc_question_options.second
    opt.value = 1
    opt.save!
    assert q.has_values?, 'has_values? returned false for question with some values'
  end

  test "option ordering" do
    # should be ordered by the `order` column
    q = create :mc_question
    o1 = create :mc_question_option, :mc_question => q, :order => 2
    o2 = create :mc_question_option, :mc_question => q, :order => 3
    o3 = create :mc_question_option, :mc_question => q, :order => 1

    assert_equal [o3, o1, o2], q.mc_question_options
  end
end