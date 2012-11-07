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

class TasksHelperTest < ActionView::TestCase
  test "interpolate" do
    data = {
      :foo => 'data1',
      :bar => 'data2',
      :baz => 'data3'
    }

    template_string = '{{foo}} - {{bar}} - {{foo}} - {{test}} - {{foo}}'
    expected_output = 'data1 - data2 - data1 - {{test}} - data1'

    assert_equal expected_output, interpolate(template_string, data)
  end

  test "markdown" do
    input = <<-END_IN.strip_heredoc
      <b>foo</b>

      <p>blah</p>

      # Things

      I want some *things* and some _other things_ and some **important things**

      * foo
      * bar

      <script type="text/javascript">alert('hi');</script>
    END_IN

    expected_output = <<-END_OUT.strip_heredoc
      <p><b>foo</b></p>

      <p>blah</p>

      <h1>Things</h1>

      <p>I want some <em>things</em> and some <em>other things</em> and some <strong>important things</strong></p>

      <ul>
      <li>foo</li>
      <li>bar</li>
      </ul>

      <script type="text/javascript">alert('hi');</script>
    END_OUT

    assert_dom_equiv expected_output, markdown(input)
  end

  test "resolve data" do
    fields = {
      'foo' => 'data1',
      'bar' => 'data2',
      'baz' => 'data3'
    }

    data = {
      :key1 => { :value => '_nil' },
      :key2 => { :value => 'foo' },
      :key3 => { :value => '_literal', :literal => 'lit' },
      :key4 => { :value => 'bar' },
      :key5 => { :value => 'foo' }
    }

    expected_output = {
      :key1 => nil,
      :key2 => 'data1',
      :key3 => 'lit',
      :key4 => 'data2',
      :key5 => 'data1'
    }

    assert_equal expected_output, resolve_data(data, fields)
  end
end