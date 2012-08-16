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

require 'net-ldap'
require 'set'

# Helper functions for LDAP authentication
class LdapAuth
  # config MUST have:
  # conn[:base_dn]
  #
  # config MUST have one of:
  # config[:conn]
  # OR
  # conn[:host] AND conn[:port] AND conn[:tls]
  #
  # config MAY have zero or more of:
  # config[:priv_groups], config[:priv_users], config[:access_user], config[:access_groups]
  #
  # config[:conn] is an instance of Net::LDAP or something that quacks like one.
  # descriptions of the other parameters are in config/auth.example_ldap_encrypted.yml
  def initialize config
    @config = config

    # build search strings
    @search_base = config[:base_dn]
    @dn_suffix = "cn=users,#{@search_base}"
    @group_search_base = "cn=groups,#{@search_base}"
    @search_attributes = %w(cn mail uid)

    if config[:conn]
      @ldap = config[:conn]
    else
      # create the connections
      opts = {:host => config[:host], :port => config[:port]}

      if config[:tls]
        opts[:encryption] = :simple_tls
      end

      @ldap = Net::LDAP.new opts
    end

    # load groups
    load_users_from_groups
  end

  # Returns the distinguished name for a user
  def dn_for username
    "uid=#{username},#{@dn_suffix}"
  end

  # attempts to bind with the specified username/password, then return the LDAP
  # record corresponding to that user
  def auth username, password
    return nil unless @access_users.member?(username)

    dn = dn_for username
    @ldap.auth dn, password
    if @ldap.bind
      ldap_obj = @ldap.search(:base => dn, :attributes => @search_attributes)[0]

      # flatten out the (single-valued) attribute arrays into a simple hash
      res = {}
      ldap_obj.each { |k,v| res[k] = v[0] }

      # mark the user as privileged or non-privileged
      if @priv_users.member?(username)
        res[:privileged] = true
      else
        res[:privileged] = false
      end

      return res
    else
      return nil
    end
  end

  # Sets the ldap connection used by this LdapAuth. Should be a Net::LDAP or
  # something that quacks like one
  def connection= conn
    @ldap = conn
    load_users_from_groups
  end

  private

  # load group memberships
  def load_users_from_groups
    @priv_users = Set.new(@config[:priv_users])
    @config[:priv_groups].each do |grp|
      @priv_users += load_users_from_group(grp)
    end

    @access_users = Set.new(@config[:access_users])
    @config[:access_groups].each do |grp|
      @access_users += load_users_from_group(grp)
    end
    @access_users += @priv_users
  end

  def load_users_from_group group_name
    result = @ldap.search :base => @group_search_base,
                          :filter => "(cn=#{group_name})"

    return result[0][:memberUid] || []
  end
end
