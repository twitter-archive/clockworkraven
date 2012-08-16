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

namespace :users do
  desc "Add a user"
  task :add => :environment do
    UserTasks.new.add
  end

  desc "Change a user's password"
  task :change_password => :environment do
    UserTasks.new.change_password
  end
end

class UserTasks
  NON_PASS_WARNING = <<END_S
WARNING:
You are not currently configured to use password authentication. Users created
in this interface will not be usable unless you modify config/auth.yml to use
password authentication. To do this, copy config/auth.example_password.yml
to config/auth.yml.
END_S

  def initialize
    unless AUTH_CONFIG[:type] == :password
      puts NON_PASS_WARNING
    end
    require 'highline'
    require 'factory_girl_rails'
    @in = HighLine.new
  end

  def add
    puts "Creating a new user"

    username = @in.ask("Username: ") do |q|
      q.validate = validate(:username)
      q.responses[:not_valid] = "Username must be unique"
    end

    begin
      pass = @in.ask("Password: ") do |q|
        q.echo = '*'
        q.validate = proc{|p| not p.blank?}
        q.responses[:not_valid] = "Password cannot be blank"
      end

      confirm = @in.ask("Confirm Password: ") do |q|
        q.echo = '*'
      end

      raise PasswordConfirmationError unless pass == confirm
    rescue PasswordConfirmationError
      puts "Password and confirmation didn't match."
      retry
    end

    email = @in.ask("Email: ") do |q|
      q.validate = validate(:email)
      q.responses[:not_valid] = "Invalid email"
    end

    name = @in.ask("Real Name: ") do |q|
      q.validate = validate(:name)
      q.responses[:not_valid] = "Invalid name"
    end

    priv = false
    puts "\nPrivileged users can work with production jobs (jobs that cost money)"
    @in.choose do |menu|
      menu.layout = :one_line
      menu.header = 'Privileged'
      menu.prompt = 'Should this user be privileged? '
      menu.choice('yes') { priv = true  }
      menu.choice('no')  { priv = false }
    end

    user = FactoryGirl.create :password_user, :username =>   username,
                                              :password =>   pass,
                                              :email =>      email,
                                              :name =>       name,
                                              :privileged => priv

    @in.choose do |menu|
      menu.layout = :one_line
      menu.header = "Successfully created user \"#{username}\""
      menu.prompt = 'Create another? '
      menu.choice('yes') { add }
      menu.choice('no')  {     }
    end
  end

  def change_password
    puts "Changing a user's password"
    user = @in.ask("Username: ", proc{ |u| User.find_by_username(u) }) do |q|
      q.validate = proc { |username| User.find_by_username(username) != nil }
    end
    pass = @in.ask("New Password: ") do |q|
      q.echo = '*'
      q.verify_match = true
      q.gather = {'New Password: ' => '', 'Confirm Password: ' => ''}
    end
    user.password = pass
    user.password_confirmation = pass
    user.save!

    @in.choose do |menu|
      menu.layout = :one_line
      menu.header = "Successfully changed password for \"#{username}\""
      menu.prompt = 'Change another? '
      menu.choice('yes') { change_password }
      menu.choice('no')  {     }
    end
  end

  def validate field
    proc do |val|
      if (FactoryGirl.build :password_user, field => val).valid?
        true
      else
        false
      end
    end
  end

  class PasswordConfirmationError < StandardError; end
end
