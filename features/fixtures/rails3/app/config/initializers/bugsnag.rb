Bugsnag.configure do |config|
  config.api_key = ENV["MAZE_API_KEY"] || ENV["BUGSNAG_API_KEY"]
  config.endpoint = ENV["MAZE_ENDPOINT"] || ENV["BUGSNAG_ENDPOINT"]
end
