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
    when '/feature-flags/unhandled'
      Bugsnag.add_on_error(proc do |event|
        event.add_feature_flag('a', '1')

        event.add_feature_flags([
          Bugsnag::FeatureFlag.new('b'),
          Bugsnag::FeatureFlag.new('c', '3'),
        ])

        event.add_feature_flag('d')

        if req.params["clear_all_flags"]
          event.clear_feature_flags
        end
      end)

      raise 'Unhandled error'
    when '/feature-flags/handled'
      Bugsnag.notify(RuntimeError.new('oh no')) do |event|
        event.add_feature_flag('x')

        event.add_feature_flags([
          Bugsnag::FeatureFlag.new('y', '1234'),
          Bugsnag::FeatureFlag.new('z'),
        ])

        if req.params["clear_all_flags"]
          event.clear_feature_flags
        end
      end
    end

    res = Rack::Response.new
    res.finish
  end
end

Rack::Server.start(app: Bugsnag::Rack.new(BugsnagTests.new), Host: '0.0.0.0', Port: 3000)
