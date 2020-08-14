Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.endpoint = ENV['BUGSNAG_ENDPOINT']
  config.session_endpoint = ENV['BUGSNAG_ENDPOINT']
end
