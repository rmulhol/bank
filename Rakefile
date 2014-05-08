require 'rspec/core/rake_task'

task :default => [:spec]

desc "Run tests"
task :spec do
  RSpec::Core::RakeTask.new { |t| t.verbose = false }
end

desc "Clean generated gem files."
task :clean do
  FileUtils.rm Dir.glob("*.gem")
end
