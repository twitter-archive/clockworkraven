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

# parts this code based on
# http://railscasts.com/episodes/197-nested-model-form-part-2?view=asciicast

module EvaluationsHelper
  # Creates a link that removes a question or an MC option.
  #
  # f: The form builder for the form.
  def link_to_remove_fields(f)
    # red X icon
    content = "<i class='icon-remove'></i>".html_safe

    # We add an _destroy field, which is used to signal to rails that a record
    # should be deleted
    return f.hidden_field(:_destroy).html_safe +
           link_to_function(content,
                            "TemplateBuilder.remove_fields(this)",
                            :class => 'btn btn-danger btn-remove')
  end

  # Creates a link that removes an artibtrary section
  #
  # hidden_field_name: Name of the hidden field that will be checked when the
  #                    section is removed, e.g. evaluation[foo][bar][_destroy]
  def link_to_remove_static_fields(hidden_field_name)
    # red X icon
    content = "<i class='icon-remove'></i>".html_safe

    # We add an _destroy field, which is used to signal to rails that a record
    # should be deleted
    return hidden_field_tag(hidden_field_name).html_safe +
           link_to_function(content,
                            "TemplateBuilder.remove_fields(this)",
                            :class => 'btn btn-danger btn-remove')
  end


  # Creates a link that adds a question or an MC option
  #
  # name:            The link text
  # icon:            Icon class to apply
  # f:               The form builder
  # association:     The association that relates the form builder's object to
  #                  the filed to be added. For example, for an Evaluation's
  #                  form builder, to create a link that adds a new MCQuestion,
  #                  pass :mc_questions for this argument. There must be
  #                  a partial named "_<association>_text.html.haml" that
  #                  renders the form fields for this association.
  # create_children: If non-nil, the created field will have sub-fields. The
  #                  values should be the association that relates the created
  #                  object to its children. For example, to create a link
  #                  that adds a new MCQuestion with MCQuestionOptions,
  #                  pass :mc_question_options for this argument.
  # link_classes:    Classes to apply to the link itself.
  def link_to_add_fields(name, icon, f, association, link_classes = '', create_children=nil)
    # Creates the new object
    new_object = f.object.class.reflect_on_association(association).klass.new

    # Create the object's children, if create_children is non-nil
    if create_children
      4.times{new_object.send(create_children).build}
    end

    # Render the partial that will be insterted via javascript when this link is
    # clicked
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(:partial => association.to_s.singularize + "_fields", :locals => {:f => builder})
    end

    # The link text is an icon and the value of the <name> argument
    content = ("<i class='#{icon}'></i> " + name).html_safe

    # Link to the javascript that will insert the partial we rendered
    link_to_function(content, "TemplateBuilder.add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => link_classes)
  end

  # Creates a link that will insert and arbitrary partial.#
  #
  # name:    The link text
  # icon:    Icon class to apply
  # partial: The name of the partial, without the "_fields" -- e.g. the partial
  #          rendered will be "_<partial>_fields.html.haml"
  def link_to_add_static_fields name, icon, partial
    # render the partial. We generate a "new_<partial name>" id (which gets
    # re-written by client-side JS to a realistic, unique ID when the
    # rendered partial is inserted). We also provide an empty item, which
    # signals to the partial that it should render empty fields rather than
    # pre-filling them with existing values.
    fields = render(:partial => partial + '_fields', :locals => {:id => "new_#{partial}", :item => {}})

    # add an icon to the link text
    content = ("<i class='#{icon}'></i> " + name).html_safe

    # Link to the javascript that will insert the partial we rendered
    link_to_function(content, "TemplateBuilder.add_fields(this, \"#{partial}\", \"#{escape_javascript(fields)}\")")
  end

  # Returns an array of [key, value] pairs, where the key is the description
  # of a component and the value is its name.
  def component_options
    COMPONENTS.map do |name, data|
      [data[:desc], name.to_s]
    end
  end

  # Returns the set of <option> tasks that allows the user to select what
  # value to assign to a component's variable. This set includes the fields
  # in the CSV the user uploaded, '_literal' for a constant literal value,
  # and, if the variable is optional, '_nil', which indicates no value.
  #
  # var_name: The name of the variable to generate options for
  # var_data: The data Hash from the COMPONENTS object
  # fields:   Fields from the evaluation's data (e.g. CSV columns)
  # item:     The existing component item -- used to pre-select current option
  def options_for_component_select var_name, var_data, fields, item
    options = []

    # _nil
    unless var_data[:required]
      options.push ['', '_nil']
    end

    # fields
    fields.each do |field|
      options.push [field, field]
    end

    # _literal
    options.push ['Literal...', '_literal']

    # figure
    current = value_for_data(var_name, item)

    return options_for_select(options, current)
  end

  # Safe equivalent to item[:data][key][value_key] -- if any step returns
  # nil, this whole method returns nil
  def value_for_data(key, item, value_key = :value)
    if item and item[:data] and item[:data][key]
      return item[:data][key][value_key]
    end
    return nil
  end
end
