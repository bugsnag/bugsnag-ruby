require 'bugsnag'
require 'rack'
require 'json'

Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.endpoint = ENV['BUGSNAG_ENDPOINT']

  if ENV.key?('BUGSNAG_METADATA_FILTERS')
    config.meta_data_filters = JSON.parse(ENV['BUGSNAG_METADATA_FILTERS'])
  end
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
