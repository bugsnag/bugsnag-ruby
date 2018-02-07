Bugsnag.configure do |config|
  config.api_key = ENV["MAZE_API_KEY"] if ENV["MAZE_API_KEY"]
  config.app_type = ENV["MAZE_APP_TYPE"] if ENV["MAZE_APP_TYPE"]
  config.app_version = ENV["MAZE_APP_VERSION"] if ENV["MAZE_APP_VERSION"]
  config.auto_capture_sessions = true if ENV["MAZE_AUTO_CAPTURE_SESSIONS"] == "true"
  config.auto_notify = false if ENV["MAZE_AUTO_NOTIFY"] == "false"
  config.endpoint = ENV["MAZE_ENDPOINT"] if ENV["MAZE_ENDPOINT"]
  config.ignore_classes = [ENV["MAZE_IGNORE_CLASS"]] if ENV["MAZE_IGNORE_CLASS"]
  config.ignore_classes = [lambda {|ex| ex.message == ENV["MAZE_IGNORE_MESSAGE"]}] if ENV["MAZE_IGNORE_MESSAGE"]
  config.meta_data_filters = [ENV["MAZE_META_DATA_FILTERS"]] if ENV["MAZE_META_DATA_FILTERS"]
  config.notify_release_stages = [ENV["MAZE_NOTIFY_RELEASE_STAGE"]] if ENV["MAZE_NOTIFY_RELEASE_STAGE"]
  config.project_root = ENV["MAZE_PROJECT_ROOT"] if ENV["MAZE_PROJECT_ROOT"]
  config.proxy_host = ENV["MAZE_PROXY_HOST"] if ENV["MAZE_PROXY_HOST"]
  config.proxy_password = ENV["MAZE_PROXY_PASSWORD"] if ENV["MAZE_PROXY_PASSWORD"]
  config.proxy_port = ENV["MAZE_PROXY_PORT"] if ENV["MAZE_PROXY_PORT"]
  config.proxy_user = ENV["MAZE_PROXY_USER"] if ENV["MAZE_PROXY_USER"]
  config.release_stage = ENV["MAZE_RELEASE_STAGE"] if ENV["MAZE_RELEASE_STAGE"]
  config.send_code = false if ENV["MAZE_SEND_CODE"] == "false"
  config.send_environment = true if ENV["MAZE_SEND_ENVIRONMENT"] == "true"
  config.session_endpoint = ENV["MAZE_SESSION_ENDPOINT"] if ENV["MAZE_SESSION_ENDPOINT"]
  config.timeout = ENV["MAZE_TIMEOUT"].to_i if ENV["MAZE_TIMEOUT"]
end
