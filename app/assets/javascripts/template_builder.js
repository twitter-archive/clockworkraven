/* Copyright 2012 Twitter, Inc. and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// template_builder.js:
// Code for the template builder on the evaluation/1/edit_template page


TemplateBuilder = {
    init: function() {
        $('.component-select').each(function(i, select) {
            TemplateBuilder.update_component(select);
        });

        $('.value-select').each(function(i, select) {
            TemplateBuilder.update_literal(select);
        });

        $( ".fields" ).sortable({
            placeholder: "ui-state-highlight",
            start: function(e, ui){
                ui.placeholder.height(ui.item.height() + 20);
            },
            stop: function(e, ui) {
                TemplateBuilder.update_orders();
            }
        });

        $('.metadata-select-box').multiselect();
        TemplateBuilder.update_orders();
    },

    // Check the "_destroy" checkbox and hide the input. Used in the form builder
    // to remove questions/options
    // this code based on http://railscasts.com/episodes/197-nested-model-form-part-2?view=asciicast
    remove_fields: function(link) {
        $(link).prev("input[type=hidden]").val("1");
        $(link).closest(".field").hide();
        TemplateBuilder.update_orders();
    },

    // add <content> to the DOM before the given <link>, using <association>
    // to genereate the id. Used in the form builder to add questions/options.
    // this code based on http://railscasts.com/episodes/197-nested-model-form-part-2?view=asciicast
    add_fields: function(link, association, content) {
        var new_id = new Date().getTime();
        var regexp = new RegExp("new_" + association, "g");
        $(link).parents('.add-parent').prev('.fields').append(content.replace(regexp, new_id));
        TemplateBuilder.init();
    },

    // changes which component section is visible based on the value of the select box
    update_component: function(select) {
        $(select).siblings('.component-details')
                 .hide()
                 .filter('[data-component=' + $(select).val() + ']')
                 .show();
    },

    // changes whether the literal text box is shown based on the value of the
    // select box
    update_literal: function(select) {
        var select = $(select);
        if(select.val() == '_literal') {
            select.next('input').show();
        }
        else {
            select.next('input').hide();
        }
    },

    // updates the hidden order fields in the each .field of a .fields
    update_orders: function() {
        $('.fields').each(function(fields_i, fields) {
            $(fields).children('.field:visible').each(function(field_i, field) {
                $(field).children('input[data-order=true]').val(field_i)
            });
        });
    },

    // Inserts a reference to the given field in the closet textarea to the
    // given link
    insert_ref: function(field, link) {
        var textarea = $(link).parents('.btn-group').siblings('textarea');
        textarea.insertAtCaret('{{' + field + '}}');
    }
}


$(function() {
    if (!/evaluations (edit|update)_template/.test($('body').attr('class'))) {
        // we're not on the task responses index page; abort
        return;
    }

    $('a[data-toggle=dropdown]').dropdown();

    TemplateBuilder.init();
})