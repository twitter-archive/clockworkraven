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

module LDAPTestHelper
  # sets up LDAP to point to an LdapAuth that's connected to a mocked LDAP
  # connection (MockLdap rather than Net::LDAP). Call the given block in the
  # context of the MockLdap so mock user acconts can be created. Also sets
  # AUTH_CONFIG[:type] to :ldap.
  def mock_ldap &block
    mock_ldap = MockLdap.new
    mock_ldap.instance_eval &block

    new_ldap = LdapAuth.new :conn          => mock_ldap,
                            :base_dn       => "dc=ldap;dc=example;dc=com",
                            :priv_groups   => mock_ldap.priv_groups,
                            :priv_users    => mock_ldap.priv_users,
                            :access_groups => mock_ldap.access_groups,
                            :access_users  => mock_ldap.access_users

    set_consts :LDAP => new_ldap
    AUTH_CONFIG[:type] = :ldap
  end

  class MockLdap
    attr_reader :priv_users, :priv_groups, :access_users, :access_groups

    def initialize
      # username => password
      @users = {}

      # group name => [members...]
      @groups = Hash.new

      @priv_users    = []
      @priv_groups   = []
      @access_users  = []
      @access_groups = []

      # whether the last #auth call was successful
      @authed = false
    end

    # setup

    # Creates a user with the given username and password. By default, this
    # user has access but it unprivileged. To override this, use
    # opts[:access] and opts[:priv]
    def user username, password, opts={}
      opts.reverse_merge! :access => true, :priv => false

      @users[username] = password

      if opts[:access]
        @access_users.push username
      end

      if opts[:priv]
        @priv_users.push username
      end
    end

    # creates a group with the given name and call the given block in the
    # context of the MockLdapGroup so user can be added to the group.
    def group name, opts={}, &block
      opts.reverse_merge! :access => true, :priv => false
      @groups[name] ||= MockLdapGroup.new(self)

      if opts[:access]
        @access_groups.push name
      end

      if opts[:priv]
        @priv_groups.push name
      end

      @groups[name].instance_eval &block
    end

    # mocked methods
    def search opts
      if opts[:filter]
        # group search
        group = parse_group opts[:filter]
        return [{:memberUid => @groups[group].to_a}]
      else
        user = parse_user opts[:base]
        if user
          return [{:cn => [user.capitalize], :uid => [user], :mail => ["#{user}@twitter.com"]}]
        else
          return []
        end
      end
    end

    def auth dn, password
      user = parse_user dn
      @authed = @users.has_key?(user) && (@users[user] == password)
    end

    def bind
      @authed
    end

    private

    # given an LDAP filter in the form "(cn=<group>)", returns the <group>
    def parse_group filter
      /^\(cn=(.*)\)$/.match(filter)[1]
    end

    # given an LDAP DN in the form "key1=value1,key2=value2,...", returns
    # the value for the key "uid"
    def parse_user search
      Hash[*search.split(',').map{|pair| pair.split('=').values_at(0..1)}.flatten]['uid']
    end

    # represents a simulated LDAP group
    class MockLdapGroup
      def initialize mock_ldap
        @members = Set.new
        @mock_ldap = mock_ldap
      end

      def to_a
        @members.to_a
      end

      # creates the user and adds it to this group. Users this way default to
      # :access => false, :priv => false (because their privileges come from
      # the group)
      def user username, password, opts = {}
        opts.reverse_merge! :access => false, :priv => false
        @mock_ldap.user username, password, opts
        add username
      end

      # adds a user to this group. The user should already have been created.
      def add username
        @members.add username
      end
    end
  end
end