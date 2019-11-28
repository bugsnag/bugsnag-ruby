require 'bugsnag'
require 'pp'

def configure_basics
  Bugsnag.configure do |conf|
    conf.api_key = ENV['BUGSNAG_API_KEY']
    conf.set_endpoints(ENV['BUGSNAG_ENDPOINT'], ENV["BUGSNAG_ENDPOINT"])
  end
end

def configure_using_environment
  Bugsnag.configure do |conf|
    conf.app_type = ENV["BUGSNAG_APP_TYPE"] if ENV.include? "BUGSNAG_APP_TYPE"
    conf.app_version = ENV["BUGSNAG_APP_VERSION"] if ENV.include? "BUGSNAG_APP_VERSION"
    conf.auto_capture_sessions = ENV["BUGSNAG_AUTO_CAPTURE_SESSIONS"] != "false"
    conf.auto_notify = ENV["BUGSNAG_AUTO_NOTIFY"] != "false"
    conf.ignore_classes << lambda { |ex| ex.class.to_s == ENV["BUGSNAG_IGNORE_CLASS"] } if ENV.include? "BUGSNAG_IGNORE_CLASS"
    conf.meta_data_filters << ENV["BUGSNAG_META_DATA_FILTERS"] if ENV.include? "BUGSNAG_META_DATA_FILTERS"
    conf.notify_release_stages = [ENV["BUGSNAG_NOTIFY_RELEASE_STAGE"]] if ENV.include? "BUGSNAG_NOTIFY_RELEASE_STAGE"
    conf.project_root = ENV["BUGSNAG_PROJECT_ROOT"] if ENV.include? "BUGSNAG_PROJECT_ROOT"
    conf.proxy_host = ENV["BUGSNAG_PROXY_HOST"] if ENV.include? "BUGSNAG_PROXY_HOST"
    conf.proxy_password = ENV["BUGSNAG_PROXY_PASSWORD"] if ENV.include? "BUGSNAG_PROXY_PASSWORD"
    conf.proxy_port = ENV["BUGSNAG_PROXY_PORT"] if ENV.include? "BUGSNAG_PROXY_PORT"
    conf.proxy_user = ENV["BUGSNAG_PROXY_USER"] if ENV.include? "BUGSNAG_PROXY_USER"
    conf.release_stage = ENV["BUGSNAG_RELEASE_STAGE"] if ENV.include? "BUGSNAG_RELEASE_STAGE"
    conf.send_environment = ENV["BUGSNAG_SEND_ENVIRONMENT"] != "false"
    conf.send_code = ENV["BUGSNAG_SEND_CODE"] != "false"
    conf.timeout = ENV["BUGSNAG_TIMEOUT"] if ENV.include? "BUGSNAG_TIMEOUT"
  end
end

def add_at_exit
  at_exit do
    if $!
      Bugsnag.notify($!, true)
    end
  end
end