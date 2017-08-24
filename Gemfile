source "https://rubygems.org"

group :test do
    gem 'rake', '~> 10.1.1'
    gem 'rspec'
    gem 'rdoc'
    gem 'pry'
    gem 'addressable', '~> 2.3.8'
    gem 'webmock', '2.3.2' if RUBY_VERSION <= '1.9.3'
end

group :coverage do
    gem 'simplecov'
    gem 'coveralls'
end

group :sidekiq do
    gem 'sidekiq', '~> 5.0.4'
end

gemspec