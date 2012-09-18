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

# Represents a job that is executing in Resque.
#
# The background thread can periodically update the job's completion attribute
# to provide status updates on progress -- the job's percent completion should
# always be job.completed / job.total
#
# Attributes
#
# resque_job:   The UUID of the Resque job.
# title:        A title, displayed to Clockwork Raven users
# complete_url: The URL to direct the user to when to job has completed
# back_url:     The URL to direct the user to if they wish to go back to their
#               previous screen while the job executes
class JobPart < ActiveRecord::Base
  belongs_to :job

  # status name => status id
  # new: not yet processed
  # done: processing completed successfully
  # error: processing raised an error
  STATUS_ID = {
    :new => 0,
    :done => 1,
    :error => 2
  }

  # status id => status name
  STATUS_NAME = STATUS_ID.invert

  validates :status, :numericality => { :only_integer => true,
                                        :greater_than_or_equal_to => 0,
                                        :less_than_or_equal_to => 2}

  # The ActiveRecord::Base#import method has issues with Rails's
  # serialization, so we do it manually here.
  def data
    return YAML.load(self[:data])
  end

  def data= new_data
    self[:data] = YAML.dump(new_data)
  end
end