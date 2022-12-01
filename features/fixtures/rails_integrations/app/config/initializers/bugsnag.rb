Bugsnag.configure do |config|
  config.api_key = ENV['BUGSNAG_API_KEY']
  config.endpoint = ENV['BUGSNAG_ENDPOINT']
  config.session_endpoint = ENV['BUGSNAG_SESSION_ENDPOINT']

  config.add_on_error(proc do |report|
    report.add_tab(:config, {
      delivery_method: config.delivery_method.to_s,
    })
  end)
end
