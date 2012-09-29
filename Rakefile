# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "bugsnag"
  gem.homepage = "http://github.com/bugsnag/bugsnag-ruby"
  gem.license = "MIT"
  gem.summary = %Q{Ruby notifier for bugsnag.com}
  gem.description = %Q{Ruby notifier for bugsnag.com}
  gem.email = "james@bugsnag.com"
  gem.authors = ["James Smith"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "bugsnag #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# RSpec tasks
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--backtrace --color']
end

task :default  => :spec