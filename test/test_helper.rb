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

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha'
#require 'mocha/integration/test_unit'

Dir[File.expand_path('helpers/**/*.rb', File.dirname(__FILE__))].each do |helper|
  require helper
end



class ActiveSupport::TestCase
  fixtures :all

  setup do
    # make sure that we can't talk to MTurk for real. Use the helpers in
    # test/helpers/m_turk_test_helper.rb to mock it out.
    MTurkUtils.instance_variable_set :@mturk_prod, mock()
    MTurkUtils.instance_variable_set :@mturk_sandbox, mock()
  end

  include FactoryGirl::Syntax::Methods
  include Mocha::API

  include ThreadingTestHelper
  include MTurkTestHelper
  include LoginTestHelper
  include LDAPTestHelper
  include JSONTestHelper
  include FixtureTestHelper
  include ConstantsTestHelper
  include ResqueTestHelper
end

class ActionController::TestCase
  include RoutingTestHelper
  include ViewTestHelper
  include DOMTestHelper
  include ViewResponseTestHelper
end

class ActionView::TestCase
  include ERB::Util

  include DOMTestHelper
end