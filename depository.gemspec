require 'rubygems/package_task'

pkg_name    = "depository"
pkg_version = "0.1.0"

spec = Gem::Specification.new do |s|
  s.name         = pkg_name
  s.version      = pkg_version
  s.summary      = "simple interface for persistence built on Sequel"
  s.description  = "simple interface for persistence built on Sequel"

  s.files        = Dir.glob('lib/depository/*.rb')
  s.require_path = 'lib'

  s.test_files   = Dir.glob('spec/*_spec.rb')

  s.author       = "Brian Pratt"
  s.email        = "brian@8thlight.com"
  s.homepage     = "http://8thlight.com"

  s.add_runtime_dependency 'sequel', '~> 4.7.0'
  s.add_runtime_dependency 'attr_protected', '~> 1.0.0'

  s.add_development_dependency 'rake', '~> 10.1.1'
  s.add_development_dependency 'rspec', '~> 2.14.1'
end
