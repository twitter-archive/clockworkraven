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

FactoryGirl.define do
  sequence(:mc_question_option_label) {|n| "MC Question Option #{n}"}
  sequence(:mc_question_option_value) {|n| n}

  factory :mc_question_option do
    ignore do
      has_value false
    end

    mc_question
    value { has_value ? FactoryGirl.generate(:mc_question_option_value) : nil }
    order { FactoryGirl.generate :order }

    label    { FactoryGirl.generate :mc_question_option_label }
  end
end