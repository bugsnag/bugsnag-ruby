require 'bugsnag'
require 'rack'
require 'json'

$clear_all_flags = false

Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.endpoint = ENV['BUGSNAG_ENDPOINT']

  if ENV.key?('BUGSNAG_METADATA_FILTERS')
    config.meta_data_filters = JSON.parse(ENV['BUGSNAG_METADATA_FILTERS'])
  end

  config.add_on_error(proc do |event|
    event.add_feature_flags([
      Bugsnag::FeatureFlag.new('from config 1'),
      Bugsnag::FeatureFlag.new('from config 2', 'abc xyz'),
    ])

    event.clear_feature_flag('should be removed!')

    if $clear_all_flags
      event.clear_feature_flags
    end
  end)
end

class BugsnagTests
  def call(env)
    req = Rack::Request.new(env)

    $clear_all_flags = !!req.params['clear_all_flags']

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
      Bugsnag.add_feature_flag('a', '1')

      Bugsnag.add_feature_flags([
        Bugsnag::FeatureFlag.new('b'),
        Bugsnag::FeatureFlag.new('c', '3'),
      ])

      Bugsnag.add_feature_flag('d')
      Bugsnag.add_feature_flag('should be removed!')

      raise 'Unhandled error'
    when '/feature-flags/handled'
      Bugsnag.add_feature_flag('x')

      Bugsnag.add_feature_flags([
        Bugsnag::FeatureFlag.new('y', '1234'),
        Bugsnag::FeatureFlag.new('z'),
      ])

      Bugsnag.add_feature_flag('should be removed!')

      Bugsnag.notify(RuntimeError.new('oh no'))
    end

    res = Rack::Response.new
    res.finish
  end
end

Rack::Server.start(app: Bugsnag::Rack.new(BugsnagTests.new), Host: '0.0.0.0', Port: 3000)
