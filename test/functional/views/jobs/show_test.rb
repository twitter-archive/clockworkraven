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

class JobsShowTest < ActionController::TestCase
  tests JobsController

  setup do
    login
  end

  test "Job title display" do
    # default title
    j = create :job, :title => nil
    get :show, :id => j.id
    assert_select 'h1:content("Job Progress")'

    # custom title
    j = create :job, :title => "Foo Job"
    get :show, :id => j.id
    assert_select 'h1:content("Foo Job")'
  end

  test "Progress bar" do
    j = create :job

    mock_status j, :pct_complete => 0, :status => 'working'

    get :show, :id => j.id
    assert_select '#progress_bar[style*="width: 0%"]'

    j = create :job

    mock_status j, :pct_complete => 50, :status => 'working'

    get :show, :id => j.id
    assert_select '#progress_bar[style*="width: 50%"]'
  end

  test "Error display" do
    # job without error
    j = create :job

    mock_status j, :status => 'working'

    get :show, :id => j.id
    assert_hidden '.alert-error'

    # job with error
    j = create :job

    mock_status j, :status => 'failed', :message => 'sadface'

    get :show, :id => j.id
    assert_visible '.alert-error'
    assert response.body.include?("sadface\n\nJob may have been partially completed")
  end
end