Bugsnag.configure do |config|
  config.api_key = ENV["BUGSNAG_API_KEY"] || ENV["MAZE_API_KEY"]
  config.endpoint = ENV["BUGSNAG_ENDPOINT"] || ENV["MAZE_ENDPOINT"]
end
