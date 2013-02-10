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

require 'set'
module ApplicationHelper
  # returns :evaluations, :jobs, :login or :other depending on what section of
  # the site the user is in.
  def section_name
    # empty path is :other
    return :other if request.path == ''

    path = request.path
    unless ClockworkRaven::Application.mounted_path.blank?
      path = path.gsub(/^#{ClockworkRaven::Application.mounted_path}/, "")
    end
    parts = path.split '/'

    return :evaluations if parts.length == 0

    # path doesn't start with /
    return :other if parts.length == 1

    # for the path /a/b/c/d, choose based on a
    case parts[1]
    when 'evaluations'
      return :evaluations
    when 'jobs'
      return :jobs
    when 'login'
      return :login
    when 'account'
      return :accounts
    else
      return :other
    end
  end

  # returns a div.alert containing message, unless message is nil.
  # The alert is given the "alert-<type>" class.
  def alert message, type
    return '' if message.nil?

    html = <<-END_HTML
      <div class="alert alert-#{h type}">
        <a href="#" class="close" data-dismiss="alert">&times;</a>
        #{h message}
      </div>
    END_HTML
    html.html_safe
  end

  # returns 'active' if the user is in the given section of the site, else
  # return ''. section should be one of :evaluations, :jobs, :login, or :other
  def active_in section
    if section_name == section
      'active'
    else
      ''
    end
  end

  # returns the current user from the controller
  def current_user
    controller.current_user
  end

  # formats a number of cents as a human-readable string.
  # e.g. 1234 => "$12.34"
  def format_cents cents
    return ActionController::Base.helpers.number_to_currency(cents / 100.0)
  end

  # returns 'display: none;' if <bool> is true, else returns ''
  def hide_if bool
    if bool
      'display: none;'
    else
      ''
    end
  end

  def require_header name, &block
    @required_headers ||= Set.new
    return if @required_headers.include?(name)

    @required_headers.add name
    content_for :required_headers, &block
  end
end
