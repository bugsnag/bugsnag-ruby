require "rubygems"
require "bundler/setup"
require "sinatra"
require "haml"
require "./app"
require "bugsnag"
 
set :run, false
set :raise_errors, true

Bugsnag.configure do |config|
    config.api_key = "8992c474f5da779ed1cd06191525ab6d"
    config.endpoint = "localhost:8000"
    config.notify_release_stages = ["development", "production"]
end

use Bugsnag::Rack
run Sinatra::Application