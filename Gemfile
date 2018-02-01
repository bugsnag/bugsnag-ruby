source "https://rubygems.org"

group :test, optional: true do
    gem 'rake', '~> 10.1.1'
    gem 'rspec'
    gem 'rspec-mocks'
    gem 'rdoc', '~> 5.1.0'
    gem 'pry'
    gem 'addressable', '~> 2.3.8'
    gem 'delayed_job' if RUBY_VERSION >= '2.2.2'
    gem 'webmock', RUBY_VERSION <= '1.9.3' ? '2.3.2': '>2.3.2'
    gem 'bugsnag-maze-runner', git: 'git@github.com:bugsnag/maze-runner.git'
end

group :coverage, optional: true do
    gem 'simplecov'
    gem 'coveralls'
end

group :sidekiq, optional: true do
    gem 'sidekiq', '~> 5.0.4'
end

gemspec
