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

# Represents a Clockwork Raven user
#
# Attributes:
#
# username:        The user's LDAP username
# key:             The user's API key
# email:           User's email
# privileged:      Boolean flag to indicate whether this user can spend money.
# name:            The user's real name
# password_digest: A bcrypt-ed digest of the users password. Note that we do not
#                  use has_secure_password for this, becuase has_secure_password
#                  requires all instances to have a password (whereas we don't
#                  use passwords for LDAP users.)
class User < ActiveRecord::Base

  # Length of the API key, in hexadecimal digits
  KEY_LENGTH = 24

  # automatically generate an API key for new users
  before_save :generate_key, :on => :new

  validates :username, :presence => true, :uniqueness => true
  validates :name, :presence => true
  validates :password, :confirmation => true
  validates :email, :format => { :with => EmailValidation::EMAIL_REGEX,
                    :message => "Must be a valid email address" }

  # don't allow mass assignment to password_digest, username, or privilege
  # level.
  attr_protected :username, :privileged, :password_digest

  # generates an API key
  def generate_key
    self.key = SecureRandom.hex(KEY_LENGTH / 2)
  end

  # we have no access to the user's password
  def password
    if password_digest
      @password ||= BCrypt::Password.new(password_digest)
    else
      nil
    end
  end

  # when setting the password, use bcrypt to hash and salt
  def password= new_pass
    # don't allow setting a blank password
    return if new_pass.blank?

    @password = BCrypt::Password.create(new_pass)
    self.password_digest = @password
  end

  class << self
    # Tries to authenticate with LDAP or password, based on configuration.
    # If successful, return the User that was authenticated.
    # If unsuccessful, returns nil.
    def auth username, password
      if AUTH_CONFIG[:type] == :password
        return auth_password(username, password)
      elsif AUTH_CONFIG[:type] == :ldap
        return auth_ldap(username, password)
      else
        raise "Invalid type in config/auth.yml. Must be :password or :ldap."
      end
    end

    private

    # Tries to authenticate with LDAP.
    # If successful, return the User that was authenticated.
    # If unsuccessful, returns nil.
    def auth_ldap username, password
      user_hash = LDAP.auth username, password
      if user_hash
        user = User.find_or_create_by_username username
        user.email = user_hash[:mail]
        user.privileged = user_hash[:privileged]
        user.name = user_hash[:cn]
        user.save!
        return user
      else
        return nil
      end
    end

    # Tries to authenticate with a password.
    # If successful, return the User that was authenticated.
    # If unsuccessful, returns nil.
    def auth_password username, password
      user = User.find_by_username username
      return nil unless (user and user.password_digest)
      if user.password == password
        return user
      else
        return nil
      end
    end
  end
end