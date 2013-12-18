# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "bugsnag"
  s.version = "1.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Smith"]
  s.date = "2013-12-17"
  s.description = "Ruby notifier for bugsnag.com"
  s.email = "james@bugsnag.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".travis.yml",
    "CHANGELOG.md",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "bugsnag.gemspec",
    "lib/bugsnag.rb",
    "lib/bugsnag/capistrano.rb",
    "lib/bugsnag/configuration.rb",
    "lib/bugsnag/delay/resque.rb",
    "lib/bugsnag/helpers.rb",
    "lib/bugsnag/mailman.rb",
    "lib/bugsnag/meta_data.rb",
    "lib/bugsnag/middleware/callbacks.rb",
    "lib/bugsnag/middleware/rack_request.rb",
    "lib/bugsnag/middleware/rails2_request.rb",
    "lib/bugsnag/middleware/rails3_request.rb",
    "lib/bugsnag/middleware/warden_user.rb",
    "lib/bugsnag/middleware_stack.rb",
    "lib/bugsnag/notification.rb",
    "lib/bugsnag/rack.rb",
    "lib/bugsnag/rails.rb",
    "lib/bugsnag/rails/action_controller_rescue.rb",
    "lib/bugsnag/rails/active_record_rescue.rb",
    "lib/bugsnag/rails/controller_methods.rb",
    "lib/bugsnag/railtie.rb",
    "lib/bugsnag/rake.rb",
    "lib/bugsnag/resque.rb",
    "lib/bugsnag/sidekiq.rb",
    "lib/bugsnag/tasks.rb",
    "lib/bugsnag/tasks/bugsnag.rake",
    "lib/bugsnag/version.rb",
    "lib/generators/bugsnag/bugsnag_generator.rb",
    "rails/init.rb",
    "spec/helper_spec.rb",
    "spec/middleware_spec.rb",
    "spec/notification_spec.rb",
    "spec/rack_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/bugsnag/bugsnag-ruby"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Ruby notifier for bugsnag.com"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.0"])
      s.add_runtime_dependency(%q<httparty>, ["< 1.0", ">= 0.6"])
      s.add_development_dependency(%q<rspec>, ["~> 2.11.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.4"])
    else
      s.add_dependency(%q<multi_json>, ["~> 1.0"])
      s.add_dependency(%q<httparty>, ["< 1.0", ">= 0.6"])
      s.add_dependency(%q<rspec>, ["~> 2.11.0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
    end
  else
    s.add_dependency(%q<multi_json>, ["~> 1.0"])
    s.add_dependency(%q<httparty>, ["< 1.0", ">= 0.6"])
    s.add_dependency(%q<rspec>, ["~> 2.11.0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
  end
end

