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

class ApplicationHelperTest < ActionView::TestCase
  test "section name" do
    @path = "/evaluations/1/task_responses/123"
    assert_equal :evaluations, section_name

    @path = "/evaluations"
    assert_equal :evaluations, section_name

    @path = "/"
    assert_equal :evaluations, section_name

    @path = "/jobs/10"
    assert_equal :jobs, section_name

    @path = "/jobs"
    assert_equal :jobs, section_name

    @path = "/login"
    assert_equal :login, section_name

    @path = ""
    assert_equal :other, section_name

    @path = "stuff"
    assert_equal :other, section_name

    @path = "evaluation"
    assert_equal :other, section_name

    @path = "/foo"
    assert_equal :other, section_name

    @path = "/foo/bar"
    assert_equal :other, section_name
  end

  test "alert" do
    assert_equal '', alert(nil, 'foo')

    expected_html_template = <<-END_HTML
      <div class="alert alert-%{type}">
        <a href="#" class="close" data-dismiss="alert">&times;</a>
        %{message}
      </div>
    END_HTML

    # basic message/type
    assert_dom_equal(expected_html_template % {:type => 'foo', :message => 'bar'},
                     alert('bar', 'foo'))

    # injection attempt
    assert_dom_equal(expected_html_template % {:type => '&lt;foo&gt;', :message => '&amp;ha'},
                     alert('&ha', '<foo>'))
  end

  test "active_in" do
    @path = "/evaluations"
    assert_equal 'active', active_in(:evaluations)
    assert_equal '', active_in(:jobs)

    @path = "/jobs"
    assert_equal 'active', active_in(:jobs)
    assert_equal '', active_in(:evaluations)

    @path = "/login"
    assert_equal 'active', active_in(:login)
    assert_equal '', active_in(:other)

    @path = "/foo"
    assert_equal 'active', active_in(:other)
    assert_equal '', active_in(:login)
  end

  test "current_user" do
    assert_equal 'testuser', current_user[:uid]
  end

  test "format_cents" do
    assert_equal '$12.34', format_cents(1234)
    assert_equal '$0.00', format_cents(0)
    assert_equal '$0.10', format_cents(10)
    assert_equal '$0.01', format_cents(1)
  end

  test "hide_if" do
    assert_equal '', hide_if(false)
    assert_equal 'display: none;', hide_if(true)
  end

  def request
    # return a mock request
    mock :path => (@path || root_path)
  end

  def controller
    # return a mock controller
    mock :current_user => {:uid => 'testuser'}
  end
end