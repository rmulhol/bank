require 'rspec/core/rake_task'

task :default => [:spec]

desc "Runs the tests"
task :spec do
  RSpec::Core::RakeTask.new { |t| t.verbose = false }
end

task "Clean up generated gem sources."
task :clean do
  FileUtils.rm Dir.glob("*.gem")
end
