require 'rspec/core/rake_task'

task :default => [:spec]

desc "Runs the tests"
task :spec do
  RSpec::Core::RakeTask.new { |t| t.verbose = false }
end
