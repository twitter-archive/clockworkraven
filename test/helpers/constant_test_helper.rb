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

module ConstantsTestHelper
  NO_CONST = Object.new

  # Sets global constants to new values, executes the block, then resets the
  # constants.
  #
  # Example:
  #
  # :AUTH_CONFIG[:type] # => :ldap
  # FOO # => const missing
  # with_constants(:AUTH_CONFIG => {:type => :password}, :FOO => 'bar') do
  #   AUTH_CONFIG[:type] # => :password
  #   FOO # => 'bar'
  # end
  # :AUTH_CONFIG[:type] # => :ldap
  # FOO # => const missing
  def with_consts consts
    old_values = {}
    consts.keys.each do |const|
      old_values[const] = const_value(const)
    end

    set_consts consts

    yield

    set_consts old_values
  end

  # Sets constants (like with_consts), but doesn't take a block and doesn't
  # reset the constsns
  def set_consts map
    map.each do |const, val|
      set_const const, val
    end
  end

  private

  def const_value const
    return Object.const_get(const)
  rescue NameError
    return NO_CONST
  end

  def set_const const, val
    if val == NO_CONST
      unset_const const
    else
      silence_warnings do
        Object.const_set const, val
      end
    end
  end

  def unset_const const
    Object.send(:remove_const, const)
  end
end