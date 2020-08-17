require 'bugsnag'
require 'rack'

Bugsnag.configure do |config|
  puts "Configuring `api_key` to #{ENV['BUGSNAG_API_KEY']}"
  config.api_key = ENV['BUGSNAG_API_KEY']
  puts "Configuring `endpoint` to #{ENV['BUGSNAG_ENDPOINT']}"
  config.endpoint = ENV['BUGSNAG_ENDPOINT']
end

class BugsnagTests
  def call(env)
    req = Rack::Request.new(env)

    case req.env['REQUEST_PATH']
    when '/unhandled'
      raise 'Unhandled error'
    when '/handled'
      begin
        raise 'Handled error'
      rescue StandardError => e
        Bugsnag.notify(e)
      end
    end

    res = Rack::Response.new
    res.finish
  end
end

Rack::Server.start(app: Bugsnag::Rack.new(BugsnagTests.new), Host: '0.0.0.0', Port: 3000)
