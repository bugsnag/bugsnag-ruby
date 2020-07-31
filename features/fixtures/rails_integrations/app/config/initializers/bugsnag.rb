Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.set_endpoints(
    ENV['BUGSNAG_ENDPOINT'],
    ENV['BUGSNAG_ENDPOINT']
  ) if ENV.include?('BUGSNAG_ENDPOINT')
end
