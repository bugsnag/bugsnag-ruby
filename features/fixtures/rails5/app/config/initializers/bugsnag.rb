Bugsnag.configure do |config|
  config.api_key = ENV["BUGSNAG_API_KEY"] || ENV["MAZE_API_KEY"]
  config.endpoint = ENV["BUGSNAG_ENDPOINT"] || ENV["MAZE_ENDPOINT"]
  config.session_endpoint = ENV["BUGSNAG_ENDPOINT"] || ENV["MAZE_ENDPOINT"]
  config.app_type = ENV["MAZE_APP_TYPE"] if ENV.include? "MAZE_APP_TYPE"
  config.app_version = ENV["MAZE_APP_VERSION"] if ENV.include? "MAZE_APP_VERSION"
  config.auto_notify = ENV["MAZE_AUTO_NOTIFY"] != "false"
  config.project_root = ENV["MAZE_PROJECT_ROOT"] if ENV.include? "MAZE_PROJECT_ROOT"
  config.ignore_classes << lambda { |ex| ex.class.to_s == ENV["MAZE_IGNORE_CLASS"] } if ENV.include? "MAZE_IGNORE_CLASS"
  config.auto_capture_sessions = ENV["MAZE_AUTO_CAPTURE_SESSIONS"] == "true"
end
