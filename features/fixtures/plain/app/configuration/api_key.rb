require './app'

configure_basics

Bugsnag.configure do |conf|
  conf.api_key = ENV["BUGSNAG_API_KEY"]
end

Bugsnag.notify(RuntimeError.new("Oh no"))