require 'mailman'
require 'bugsnag'
require 'pp'

Bugsnag.configure do |conf|
  puts "Configuring `api_key` to #{ENV['BUGSNAG_API_KEY']}"
  conf.api_key = ENV['BUGSNAG_API_KEY']
  puts "Configuring `endpoint` to #{ENV['BUGSNAG_ENDPOINT']}"
  conf.endpoint = ENV['BUGSNAG_ENDPOINT']
end

Mailman.config.ignore_stdin = false

Mailman::Application.run do
  subject "Unhandled" do
    raise RuntimeError.new("Unhandled exception")
  end

  subject "Handled" do
    begin
      raise RuntimeError.new("Handled exception")
    rescue => exception
      Bugsnag.notify(exception)
    end
  end
end