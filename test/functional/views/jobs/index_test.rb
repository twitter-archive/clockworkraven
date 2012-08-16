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

class JobsIndexTest < ActionController::TestCase
  tests JobsController

  setup do
    login

    # remove old evaluations
    Job.all.each{|e| e.destroy }
  end

  test "Jobs shown in table" do
    e1 = create :job, :title => 'Name 1'
    e2 = create :job, :title => 'Name 2'

    get :index

    # check that the first column shows the names in the correct order
    assert_select 'tbody tr:first-child td:first-child:content("Name 2")'
    assert_select 'tbody tr:nth-child(2) td:first-child:content("Name 1")'
  end
end