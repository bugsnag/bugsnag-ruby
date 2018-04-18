require 'bugsnag'
require 'pp'

def configure_basics
  Bugsnag.configure do |conf|
    conf.api_key = ENV['MAZE_API_KEY']
    conf.endpoint = ENV['MAZE_ENDPOINT']
    conf.session_endpoint = ENV["MAZE_SESSION_ENDPOINT"] if ENV.include? "MAZE_SESSION_ENDPOINT"
  end
end

def configure_using_environment
  pp ENV
  Bugsnag.configure do |conf|
    conf.app_type = ENV["MAZE_APP_TYPE"] if ENV.include? "MAZE_APP_TYPE"
    conf.app_version = ENV["MAZE_APP_VERSION"] if ENV.include? "MAZE_APP_VERSION"
    conf.auto_capture_sessions = ENV["MAZE_AUTO_CAPTURE_SESSIONS"] != "false"
    conf.auto_notify = ENV["MAZE_AUTO_NOTIFY"] != "false"
    conf.ignore_classes << lambda { |ex| ex.class.to_s == ENV["MAZE_IGNORE_CLASS"] } if ENV.include? "MAZE_IGNORE_CLASS"
    conf.meta_data_filters << ENV["MAZE_META_DATA_FILTERS"] if ENV.include? "MAZE_META_DATA_FILTERS"
    conf.notify_release_stages = [ENV["MAZE_NOTIFY_RELEASE_STAGE"]] if ENV.include? "MAZE_NOTIFY_RELEASE_STAGE"
    conf.project_root = ENV["MAZE_PROJECT_ROOT"] if ENV.include? "MAZE_PROJECT_ROOT"
    conf.proxy_host = ENV["MAZE_PROXY_HOST"] if ENV.include? "MAZE_PROXY_HOST"
    conf.proxy_password = ENV["MAZE_PROXY_PASSWORD"] if ENV.include? "MAZE_PROXY_PASSWORD"
    conf.proxy_port = ENV["MAZE_PROXY_PORT"] if ENV.include? "MAZE_PROXY_PORT"
    conf.proxy_user = ENV["MAZE_PROXY_USER"] if ENV.include? "MAZE_PROXY_USER"
    conf.release_stage = ENV["MAZE_RELEASE_STAGE"] if ENV.include? "MAZE_RELEASE_STAGE"
    conf.send_environment = ENV["MAZE_SEND_ENVIRONMENT"] != "false"
    conf.send_code = ENV["MAZE_SEND_CODE"] != "false"
    conf.timeout = ENV["MAZE_TIMEOUT"] if ENV.include? "MAZE_TIMEOUT"
  end
end

def add_at_exit
  at_exit do
    if $!
      Bugsnag.notify($!, true)
    end
  end
end