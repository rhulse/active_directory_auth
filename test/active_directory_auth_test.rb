require 'test_helper'

User.authenticates_with_active_directory do |config|
  config.host    = "ldap.example.com"
  config.base_dn = "DC=example,DC=com"
  config.administrator_dn = "CN=administrator,OU=Administrators Group,OU=Systems"
  config.administrator_password = "admin"
  
  config.roles :printer_operator => "CN=Printer Operators,CN=Groups",
               :backup_operator  => "CN=Backup Operators,CN=Groups",
               :admin            => "CN=Administrators,CN=Groups"
end

def User.find_from_ldap(ldap_user)
  ldap_user
end

class ActiveDirectoryAuthTest < ActiveSupport::TestCase
  def setup
    @ldap_connection = mock()
    ActiveDirectoryAuth::LdapConnection.any_instance.
                                        expects(:new_ldap_connection).
                                        returns(@ldap_connection)
    #
    @criteria = mock()
    ActiveDirectoryAuth::LdapConnection.any_instance.
                                        expects(:new_ldap_criteria).
                                        returns(@criteria).with("koz")                                       
                                        
    @ldap_connection.expects(:host=).with("ldap.example.com")
    # @ldap_connection.expects(:host=).with("ldap.example.com")    
    @ldap_connection.expects(:auth).with('CN=administrator,OU=Administrators Group,OU=Systems,DC=example,DC=com', 'admin')
    @ldap_connection.expects(:bind_as).
        with(:password => 'password', 
             :base => 'DC=example,DC=com', 
             :filter => @criteria, 
             :attributes => ['dn', 'sAMAccountName', 'displayname', 'SN', 'givenName', 'memberOf']).
        returns(stub(:samaccountname=>"koz", :memberOf=>["CN=Printer Operators,CN=Groups", "CN=Backup Operators,CN=Groups,DC=example,DC=com"]))
    
  end
  
  test "authenticate does what it should" do
    ldap_user = User.authenticate("koz", "password")
    assert ldap_user.printer_operator?
    assert ldap_user.backup_operator?
    assert !ldap_user.admin?
  end
end
