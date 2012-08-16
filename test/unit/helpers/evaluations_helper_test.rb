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

class EvaluationsHelperTest < ActionView::TestCase
  setup do
    # we make render() return this mock object instead of actually rendering
    # a partial. To expect a call to render(*args), expect a call to
    # @render_mock.render(*args)
    @render_mock = mock
  end

  test "link to remove fields" do
    # mock out the form builder
    builder = mock
    builder.stubs(:hidden_field).with(:_destroy).returns(<<-END_HTML)
      <input id="evaluation_fr_questions_attributes_0__destroy"
             name="evaluation[fr_questions_attributes][0][_destroy]"
            type="hidden" value="false" />
    END_HTML

    expected_html = <<-END_HTML
      <input id="evaluation_fr_questions_attributes_0__destroy"
             name="evaluation[fr_questions_attributes][0][_destroy]"
             type="hidden"
             value="false" />

      <a class="btn btn-danger btn-remove" href="#" onclick="TemplateBuilder.remove_fields(this); return false;">
        <i class='icon-remove'></i>
      </a>
    END_HTML

    assert_dom_equiv expected_html, link_to_remove_fields(builder)
  end

  test "link to remove static fields" do
    expected_html = <<-END_HTML
      <input id="foo"
             name="foo"
             type="hidden" />

      <a class="btn btn-danger btn-remove" href="#" onclick="TemplateBuilder.remove_fields(this); return false;">
        <i class='icon-remove'></i>
      </a>
    END_HTML

    assert_dom_equiv expected_html, link_to_remove_static_fields('foo')
  end

  test "link to add fields without children" do
    # mock out the form builder
    builder = mock
    new_builder = mock
    new_fr_question = create :fr_question

    builder.stubs(:object).returns(create :evaluation)
    builder.expects(:fields_for).
            with(:fr_questions, new_fr_question, :child_index => 'new_fr_questions').
            yields(new_builder).
            returns('RENDERING')

    @render_mock.expects(:render).
                 with(:partial => 'fr_question_fields', :locals => {:f => new_builder})

    # Make FRQuestion.new return the mock rather than a new FRQuestion
    FRQuestion.stubs(:new).returns(new_fr_question)

    expected_html = <<-END_HTML
      <a class="thing1 thing2"
         href="#"
         onclick="TemplateBuilder.add_fields(this, &quot;fr_questions&quot;, &quot;RENDERING&quot;); return false;">

        <i class='icon-foo'></i>
        Title</a>
    END_HTML

    assert_dom_equiv expected_html, link_to_add_fields('Title', 'icon-foo', builder, :fr_questions, 'thing1 thing2')
  end

  test "link to add fields with children" do
    # mock out the form builder
    builder = mock
    new_builder = mock
    new_mc_question = create :mc_question

    builder.stubs(:object).returns(create :evaluation)
    builder.expects(:fields_for).
            with(:mc_questions, new_mc_question, :child_index => 'new_mc_questions').
            yields(new_builder).
            returns('RENDERING')

    @render_mock.expects(:render).
                 with(:partial => 'mc_question_fields', :locals => {:f => new_builder})

    # we expect link_to_add_fields to create 4 children
    relation_mock = mock
    new_mc_question.stubs(:mc_question_options).returns(relation_mock)
    relation_mock.expects(:build).times(4)

    # Make MCQuestion.new return the mock rather than a new MCQuestion
    MCQuestion.stubs(:new).returns(new_mc_question)

    expected_html = <<-END_HTML
      <a href="#"
         onclick="TemplateBuilder.add_fields(this, &quot;mc_questions&quot;, &quot;RENDERING&quot;); return false;">

        <i class='icon-foo'></i>
        Title</a>
    END_HTML

    assert_dom_equiv expected_html,
                     link_to_add_fields('Title', 'icon-foo', builder, :mc_questions, nil, :mc_question_options)
  end

  test "link to add static fields" do
    @render_mock.expects(:render).
                 with(:partial => 'foo_fields',
                      :locals => {:id => 'new_foo', :item => {}}).
                 returns('RENDERING')

    expected_html = <<-END_HTML
      <a href="#"
         onclick="TemplateBuilder.add_fields(this, &quot;foo&quot;, &quot;RENDERING&quot;); return false;">

        <i class='icon-bar'></i>
        Linky</a>
    END_HTML

    assert_dom_equiv expected_html, link_to_add_static_fields('Linky', 'icon-bar', 'foo')
  end

  test "component options" do
    components = {
      :foo => {:desc => 'desc 1'},
      :bar => {:desc => 'desc 2'},
      :baz => {:desc => 'desc 3'}
    }

    with_consts(:COMPONENTS => components) do
      assert_equal [['desc 1', 'foo'], ['desc 2', 'bar'], ['desc 3', 'baz']], component_options
    end
  end

  test "options for component select" do
    fields = ['a', 'b']

    vars = {
      :foo => {:desc => "Desc 1", :required => true},
      :bar => {:desc => "Desc 2", :required => false}
    }

    existing_item = {
      :data => {
        :foo => {:value => 'b'},
        :bar => {:value => '_literal', :literal => 'some stuff'}
      }
    }

    # required, no existing item
    expected_html = <<-END_HTML
      <option value="a">a</option>
      <option value="b">b</option>
      <option value="_literal">Literal...</option>
    END_HTML
    assert_dom_equiv expected_html, options_for_component_select(:foo, vars[:foo], fields, nil)

    # optional, no existing item
    expected_html = <<-END_HTML
      <option value="_nil"></option>
      <option value="a">a</option>
      <option value="b">b</option>
      <option value="_literal">Literal...</option>
    END_HTML
    assert_dom_equiv expected_html, options_for_component_select(:bar, vars[:bar], fields, nil)

    # required, existing item
    expected_html = <<-END_HTML
      <option value="a">a</option>
      <option value="b" selected="selected">b</option>
      <option value="_literal">Literal...</option>
    END_HTML
    assert_dom_equiv expected_html, options_for_component_select(:foo, vars[:foo], fields, existing_item)

    # optional, existing item
    expected_html = <<-END_HTML
      <option value="_nil"></option>
      <option value="a">a</option>
      <option value="b">b</option>
      <option value="_literal" selected="selected">Literal...</option>
    END_HTML
    assert_dom_equiv expected_html, options_for_component_select(:bar, vars[:bar], fields, existing_item)
  end

  test "value for data" do
    assert_equal nil, value_for_data(:foo, nil)
    assert_equal nil, value_for_data(:foo, {:data => nil})
    assert_equal nil, value_for_data(:foo, {:hello => {:foo => {:value => 10}}})
    assert_equal nil, value_for_data(:foo, {:data => {:foo => nil}})
    assert_equal nil, value_for_data(:foo, {:data => {:hello => {:value => 10}}})
    assert_equal nil, value_for_data(:foo, {:data => {:foo => {:value => nil}}})
    assert_equal nil, value_for_data(:foo, {:data => {:foo => {:hello => 10}}})
    assert_equal 10, value_for_data(:foo, {:data => {:foo => {:value => 10}}})

    assert_equal nil, value_for_data(:foo, {:data => {:foo => {:value => 10}}}, :hello)
    assert_equal 10, value_for_data(:foo, {:data => {:foo => {:hello => 10}}}, :hello)
  end

  # Make render() return a mock object instead of actually rendering a partial
  def render *args
    @render_mock.render(*args)
  end
end