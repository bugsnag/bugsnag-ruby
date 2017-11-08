# encoding: utf-8

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "bugsnag #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# RSpec tasks
require 'rspec/core'
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ""
  begin
    require 'sidekiq/testing'
  rescue LoadError
    puts "Skipping sidekiq tests, missing dependencies"
    task.rspec_opts << " --exclude-pattern **/integrations/sidekiq_spec.rb"
  end
  begin
    require 'delayed_job'
  rescue LoadError
    puts "Skipping delayed_job tests, missing dependencies"
    task.rspec_opts << " --exclude-pattern **/integrations/delayed_job_spec.rb"
  end
end

task :default  => :spec
