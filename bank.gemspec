require 'rubygems/package_task'

VERSION     = "0.1.8"

spec = Gem::Specification.new do |s|
  s.name         = "bank"
  s.version      = VERSION
  s.summary      = "simple interface for persistence built on Sequel"
  s.description  = "wraps Sequel to provide a non-ORM data-mapping interface"

  s.license      = 'WTFPL'

  s.files        = Dir.glob('lib/bank/*.rb')
  s.require_path = 'lib'

  s.test_files   = Dir.glob('spec/*_spec.rb')

  s.author       = "Brian Pratt"
  s.email        = "brian@8thlight.com"
  s.homepage     = "https://github.com/pratt121/bank"

  s.add_runtime_dependency 'sequel', '~> 4.7', '>= 4.7.0'
  s.add_runtime_dependency 'attr_protected', '~> 1.0', '>= 1.0.0'

  s.add_development_dependency 'rake', '~> 10.1', '>= 10.1.1'
  s.add_development_dependency 'rspec', '~> 2.14', '>= 2.14.1'
end
