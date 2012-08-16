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
  sequence(:mc_question_label) {|n| "MC Question #{n}"}

  factory :mc_question do
    evaluation

    metadata 0
    label    { FactoryGirl.generate :mc_question_label }
    order    { FactoryGirl.generate :order }

    factory :mc_question_with_options do
      ignore do
        option_count        5
        options_have_values false
      end

      after_create do |mc_question, evaluator|
        FactoryGirl.create_list :mc_question_option,
                                evaluator.option_count,
                                :mc_question => mc_question,
                                :has_value => evaluator.options_have_values
      end
    end
  end
end