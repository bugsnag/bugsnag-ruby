# encoding: utf-8

require 'yard'
require 'rspec/core'
require "rspec/core/rake_task"

# Yard task (rake yard)
YARD::Rake::YardocTask.new do |task|
  version = File.read("VERSION").strip

  task.options += ["--title", "bugsnag-ruby v#{version} API Documentation"]
end

# RSpec tasks
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

task default: :spec
