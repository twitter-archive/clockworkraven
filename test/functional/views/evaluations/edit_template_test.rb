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

class EvaluationsEditTemplateTest < ActionController::TestCase
  tests EvaluationsController

  setup do
    login
  end

  test "Fields shown as metadata" do
    e = create :evaluation_with_tasks
    get :edit_template, :id => e.id
    e.tasks.first.data.keys.each do |field|
      assert_select "select[name='evaluation[metadata][]'] option[value=#{field}]:content(#{field})"
    end
  end
end