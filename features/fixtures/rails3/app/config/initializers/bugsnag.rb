Bugsnag.configure do |config|
  config.api_key = ENV["BUGSNAG_API_KEY"] || ENV["MAZE_API_KEY"]
  config.endpoint = ENV["BUGSNAG_ENDPOINT"] || ENV["MAZE_ENDPOINT"]
  config.app_type = ENV["MAZE_APP_TYPE"] if ENV.include? "MAZE_APP_TYPE"
end
