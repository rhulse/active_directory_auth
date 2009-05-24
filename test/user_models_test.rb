require 'test_helper'

class UserModelsTest < ActiveSupport::TestCase
  def setup
  end
  include ActiveDirectoryAuth
  
  test "Stub user roles work right" do
    @stub_user = StubUser.new("koz", "password", [:admin, :librarian])
    assert @stub_user.admin?
    assert @stub_user.librarian?
    assert !@stub_user.hax?
    assert_equal [:admin, :librarian].to_set,
                 @stub_user.roles.to_set
  end
  
  # test ""
  
  
end