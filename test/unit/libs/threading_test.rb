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

class ThreadingTest < ActiveSupport::TestCase
  test "thread pool" do
    without_threading do
      mock_obj = mock
      mock_obj.stubs(:call).with(1).once.returns(10)
      mock_obj.stubs(:call).with(2).once.returns(20)
      mock_obj.stubs(:call).with(3).once.returns(30)

      r = Threading.thread_pool [1,2,3] do |arg|
        mock_obj.call(arg)
      end

      # assert that the return value is the return values of the blocks.
      assert_equal [10, 20, 30], r
    end
  end

  test "thread pool retries" do
    without_threading do
      # check that thread pool retries on error

      mock_obj = mock
      mock_obj.stubs(:call).with(1).times(2)
      mock_obj.stubs(:call).with(2).once
      mock_obj.stubs(:call).with(3).once
      has_errored = false

      Threading.thread_pool [1,2,3] do |arg|
        mock_obj.call arg
        if arg == 1 and !has_errored
          has_errored = true
          raise
        end
      end
    end
  end

  test "thread pool propagates persistant error" do
    without_threading do
      # check that if the thread pool runs out of retries, it throws the error
      # and aborts
      mock_obj = mock
      mock_obj.stubs(:call).with(1).times(3)

      assert_raise SpecialError do
        Threading.thread_pool [1,2,3] do |arg|
          mock_obj.call arg
          raise SpecialError
        end
      end
    end
  end

  test "thread pool does not retry Killed error" do
    without_threading do
      mock_obj = mock
      mock_obj.stubs(:call).with(1).once

      assert_raise Resque::Plugins::Status::Killed do
        Threading.thread_pool [1,2,3] do |arg|
          mock_obj.call arg
          raise Resque::Plugins::Status::Killed
        end
      end
    end
  end

  class SpecialError < RuntimeError; end
end