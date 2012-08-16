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

TEST_TWEETS = [225255947948396545, 12289148828258304, 225625063729278976, 225628700178264064]

FactoryGirl.define do
  sequence(:task_content) {|n| "Task Content #{n}"}
  sequence(:hit_id) {|n| "HIT_#{n}"}
  sequence(:tweet_id) {|n| TEST_TWEETS[n % TEST_TWEETS.length] }

  factory :task do
    evaluation

    mturk_hit nil

    data {
      {
        'item1'     => FactoryGirl.generate(:task_content),
        'item2'     => FactoryGirl.generate(:task_content),
        'tweet'     => FactoryGirl.generate(:tweet_id),
        'metadata1' => FactoryGirl.generate(:task_content),
        'metadata2' => FactoryGirl.generate(:task_content)
      }
    }

    factory :submitted_task do
      mturk_hit { FactoryGirl.generate :hit_id }
    end
  end
end