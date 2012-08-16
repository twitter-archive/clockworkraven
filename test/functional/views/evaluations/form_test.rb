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

class EvaluationsFormTest < ActionController::TestCase
  tests EvaluationsController

  setup do
    login
  end

  test "Errors shown correctly" do
    post :create, :evaluation => {:payment => 0}
    assert_select '#error_explanation li:content("Payment must be greater than or equal to 1")'
  end
end