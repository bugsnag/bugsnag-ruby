require "bugsnag/deploy"

if defined?(Capistrano::VERSION) && Gem::Version.new(Capistrano::VERSION).release >= Gem::Version.new('3.0.0')
  load File.expand_path('../tasks/bugsnag.cap', __FILE__)
else
  require_relative 'capistrano2'
end
