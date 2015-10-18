$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "active_directory_auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "active_directory_auth"
  s.version     = ActiveDirectoryAuth::VERSION
  s.authors     = ["Michael Koziarski"]
  s.email       = []
  s.summary     = %q{A plugin to allow rails apps to authenticate to Active Directory (converted to work as a gem)}
  s.homepage    = "https://github.com/rhulse/active_directory_auth"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.22"
  s.add_dependency "ruby-net-ldap"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "mocha"
end
