source "https://rubygems.org"

ruby_version = Gem::Version.new(RUBY_VERSION.dup)

group :test, optional: true do
  gem 'rake', ruby_version <= Gem::Version.new('1.9.3') ? '~> 11.3.0' : '~> 12.3.0'
  gem 'rspec'
  gem 'rspec-mocks'
  gem 'yard', ruby_version < Gem::Version.new('2.3.0') ? '< 0.9.27' : '~> 0.9.25'
  gem 'pry'
  gem 'addressable', '~> 2.3.8'

  if ruby_version >= Gem::Version.new('2.2.2')
    gem 'delayed_job', ruby_version < Gem::Version.new('2.5.0') ? '4.1.7': '>4.1.7'
    gem 'i18n', ruby_version <= Gem::Version.new('2.3.0') ? '1.4.0' : '>1.4.0'
  end

  gem 'webmock', ruby_version <= Gem::Version.new('1.9.3') ? '2.3.2': '>2.3.2'
  gem 'crack', '< 0.4.5' if ruby_version <= Gem::Version.new('1.9.3')

  gem 'hashdiff', ruby_version <= Gem::Version.new('1.9.3') ? '0.3.8': '>0.3.8'

  if ruby_version >= Gem::Version.new('2.3.0') && ruby_version <= Gem::Version.new('2.4.0')
    gem 'did_you_mean', '~> 1.0.4'
  end

  # WEBrick is no longer in the stdlib in Ruby 3.0
  gem 'webrick' if ruby_version >= Gem::Version.new('3.0.0')

  gem 'rexml', '< 3.2.5' if ruby_version == Gem::Version.new('2.0.0')

  if ruby_version >= Gem::Version.new('2.2.0') && ruby_version < Gem::Version.new('2.4.0')
    gem 'minitest', '< 5.16.0'
    gem 'connection_pool', '< 2.3.0'
  end
end

group :coverage, optional: true do
  gem 'simplecov'
  gem 'coveralls'
end

group :rubocop, optional: true do
  gem 'rubocop', '~> 1.0.0'
end

group :sidekiq, optional: true do
  gem 'sidekiq', '~> 5.2.7'

  if ruby_version < Gem::Version.new('2.3.0')
    # redis 4.1.2 dropped support for Ruby 2.2
    gem 'redis', '4.1.1'
  elsif ruby_version < Gem::Version.new('2.4.0')
    # redis 4.5.0 dropped support for Ruby 2.3
    gem 'redis', '< 4.5.0'
  else
    gem 'redis'
  end

  # rack 2.2.0 dropped support for Ruby 2.2
  gem 'rack', ruby_version < Gem::Version.new('2.3.0') ? '< 2.2.0' : '~> 2.2'

  # rack-protection 3.0.0 requires Ruby 2.6+
  gem 'rack-protection', '< 3.0.0' if ruby_version < Gem::Version.new('2.6.0')
end

gemspec
