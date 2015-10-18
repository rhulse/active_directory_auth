# ActiveDirectoryAuth

require 'net/ldap'

module ActiveDirectoryAuth
  class LdapConnection
    attr_accessor :host, :base_dn, :administrator_dn, :administrator_password,
                  :fetched_attributes


    def initialize(clazz)
      @clazz = clazz
      @host = "localhost"
      @fetched_attributes = ['dn','sAMAccountName','displayname','SN','givenName', 'memberOf', 'mail']
    end

    def roles(mapping)
      @roles_mapping = mapping
    end

    def authenticate(username, password)
      ldap = new_ldap_connection
      ldap.host = @host

      if @administrator_dn
        Rails.logger.info([@administrator_dn, @base_dn].join(','))
        ldap.auth [@administrator_dn, @base_dn].join(','), @administrator_password
      end

      if results = ldap.bind_as(:base       => @base_dn,
                                :filter     => new_ldap_criteria(username),
                                :attributes => @fetched_attributes,
                                :password   => password)
        ad_user = results.first
        Rails.logger.info "Successfully bound as #{username.inspect}"
        Rails.logger.info "Found #{ad_user.inspect}"

        ldap_user = LdapUser.new
        ldap_user.username = ad_user.samaccountname.first rescue nil
        ldap_user.first_name = ad_user.givenname.first rescue nil
        ldap_user.last_name = ad_user.sn.first rescue nil
        ldap_user.display_name = ad_user.displayname.first rescue nil
        ldap_user.email = ad_user.mail.first rescue nil
        ldap_user.roles = map_roles(ad_user.memberOf)

        @clazz.find_from_ldap(ldap_user)
      else
        Rails.logger.info "Failed to bind as #{username.inspect} Error: #{ldap.get_operation_result.inspect}"
        nil
      end
    end

    def new_ldap_connection
      Net::LDAP.new
    end

    def new_ldap_criteria(username)
      Net::LDAP::Filter.eq( "sAMAccountName", username )
    end

    def map_roles(roles)
      @roles_mapping && @roles_mapping.each_with_object(Set.new) do |pair, memo|
        pretty_name, ldap_name = pair
        if roles.include?(ldap_name)|| roles.include?([ldap_name, @base_dn].join(','))
          memo << pretty_name
        end
      end
    end
  end

  class StubConnection
    def initialize(clazz)
      @clazz = clazz
      @credentials = {}
    end

    def user(username, password, *roles)
      @credentials[username] = StubUser.new(username, password, roles)
    end

    def authenticate(username, password)
      if (user = @credentials[username]) && user.password == password
        return @clazz.find_from_ldap(user)
      else
        return nil
      end
    end
  end

  class LdapUser
    attr_accessor :username, :first_name, :last_name, :display_name, :email, :roles

    def method_missing(name, *args)
      name_s = name.to_s
      if name_s.ends_with?("?")
        @roles.include? name_s[0..-2].to_sym
      else
        super
      end
    end
  end

  class StubUser < LdapUser
    attr_reader :password

    def initialize(username, password, roles)
      self.username = username
      self.roles = roles
      @password = password
    end
  end

  module BaseMethods
    def authenticates_with_active_directory
      yield @ad_config = ActiveDirectoryAuth::LdapConnection.new(self)
      extend Authenticate
    end

    def stub_active_directory_authentication
      yield @ad_config = ActiveDirectoryAuth::StubConnection.new(self)
      extend Authenticate
    end

  end

  module Authenticate
    def authenticate(user, password)
      @ad_config.authenticate(user, password)
    end

    def find_from_ldap(ldap_user)
      find_by_login(ldap_user.username)
    end
  end
end

ActiveRecord::Base.extend(ActiveDirectoryAuth::BaseMethods)