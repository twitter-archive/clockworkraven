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
  sequence(:evaluation_name) {|n| "Evaluation #{n}"}

  factory :evaluation do
    user

    name                { FactoryGirl.generate :evaluation_name }
    desc                "Choose a tweet"
    payment             30
    keywords            "twitter, mock, test"
    mturk_hit_type      "mock_hit"
    duration            3600
    lifetime            604800
    auto_approve        86400
    status              0
    mturk_qualification "none"
    title               "Pick a tweet"
    note                "Mock evaluation"
    prod                0

    metadata ['metadata1', 'metadata2']

    template [
      {
        :type => :_header,
        :content => "Header 1"
      },
      {
        :type => :_text,
        :content => "item 1 is {{item1}}."
      },
      {
        :type => :_header,
        :content => "Item 2 Is: {{item2}}"
      },
      {
        :type => 'tweet',
        :data => {
          :tweet_id => { :value => "tweet" }
        }
      },
      {
        :type => 'user_link_given_username',
        :data => {
          :username => { :value => '_literal', :literal => 'benweissmann' }
        }
      },
      {
        :type => 'user',
        :data => {
          :profile_image => { :value => '_nil'                          },
          :name          => { :value => '_nil'                          },
          :username      => { :value => '_literal', :literal => 'echen' },
          :bio           => { :value => '_nil'                          },
          :location      => { :value => '_nil'                          },
          :website       => { :value => '_nil'                          },
          :recent_tweets => { :value => 'tweet'                         },
          :retweets      => { :value => '_nil'                          },
          :favorites     => { :value => '_nil'                          }
        }
      }
    ].map{|hsh| HashWithIndifferentAccess.new(hsh)}

    trait :tasks do
      ignore do
        task_count 5
      end

      after_create do |evaluation, evaluator|
        FactoryGirl.create_list :task, evaluator.task_count, :evaluation => evaluation
      end
    end

    trait :questions do
      ignore do
        mc_count            2
        fr_count            2
        mc_option_count     5
        options_have_values false
      end
      after_create do |evaluation, evaluator|
        FactoryGirl.create_list :fr_question,
                                evaluator.fr_count,
                                :evaluation => evaluation

        FactoryGirl.create_list :mc_question_with_options,
                                evaluator.mc_count,
                                :evaluation => evaluation,
                                :option_count => evaluator.mc_option_count,
                                :options_have_values => evaluator.options_have_values

        # add fr questions to template
        evaluation.fr_questions.sort_by{|q| q.order}.each do |q|
          evaluation.template += [{:type => :_fr, :order => q.order}]
        end

        # add mc questions to template
        evaluation.mc_questions.sort_by{|q| q.order}.each do |q|
          evaluation.template += [{:type => :_mc, :order => q.order}]
        end

        evaluation.save!
      end
    end

    factory :evaluation_with_tasks,               :traits => [:tasks]
    factory :evaluation_with_questions,           :traits => [:questions]
    factory :evaluation_with_tasks_and_questions, :traits => [:tasks, :questions]
  end
end