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
  integration_exclusions = []
  begin
    require 'sidekiq/testing'
  rescue LoadError
    puts "Skipping sidekiq tests, missing dependencies"
    integration_exclusions << 'sidekiq'
  end
  begin
    require 'delayed_job'
  rescue LoadError
    puts "Skipping delayed_job tests, missing dependencies"
    integration_exclusions << 'delayed_job'
  end
  if integration_exclusions.length > 0
    pattern = integration_exclusions.join(',')
    task.rspec_opts = " --exclude-pattern **/integrations/{#{pattern}}_spec.rb"
  end
end

task :default  => :spec
