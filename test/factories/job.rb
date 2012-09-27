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
  sequence(:resque_uuid) {|n| "resqueuuid#{n}"}
  factory :job do
    title        "Sample Task"
    complete_url "/"
    back_url     "/"
    processor    Job::ThreadPoolProcessor
    resque_job   { FactoryGirl.generate :resque_uuid }

    factory :unsubmitted_job do
      resque_job nil
    end

    factory :job_with_parts do
      ignore do
        part_count 5
      end

      after_create do |job, evaluator|
        FactoryGirl.create_list :job_part, evaluator.part_count, :job => job
      end
    end
  end
end