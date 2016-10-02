require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :codeclimate do
  sh 'CODECLIMATE_REPO_TOKEN=aaf36ba538c166427e081ca1d282bdd3b564484e42ce2859b8a75e2a582a5755 codeclimate-test-reporter'
end

task :default => :test
