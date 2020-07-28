Bugsnag.configure do |config|
  config.api_key = ENV["BUGSNAG_API_KEY"] || ENV["BUGSNAG_API_KEY"]
  config.endpoint = ENV["BUGSNAG_ENDPOINT"] || ENV["BUGSNAG_ENDPOINT"]
  config.session_endpoint = ENV["BUGSNAG_ENDPOINT"] || ENV["BUGSNAG_ENDPOINT"]
  config.app_type = ENV["BUGSNAG_APP_TYPE"] if ENV.include? "BUGSNAG_APP_TYPE"
  config.app_version = ENV["BUGSNAG_APP_VERSION"] if ENV.include? "BUGSNAG_APP_VERSION"
  config.auto_notify = ENV["BUGSNAG_AUTO_NOTIFY"] != "false"
  config.project_root = ENV["BUGSNAG_PROJECT_ROOT"] if ENV.include? "BUGSNAG_PROJECT_ROOT"
  config.ignore_classes << lambda { |ex| ex.class.to_s == ENV["BUGSNAG_IGNORE_CLASS"] } if ENV.include? "BUGSNAG_IGNORE_CLASS"
  config.auto_capture_sessions = ENV["BUGSNAG_AUTO_CAPTURE_SESSIONS"] == "true" unless ENV["USE_DEFAULT_AUTO_CAPTURE_SESSIONS"] == "true"
  config.send_code = ENV["BUGSNAG_SEND_CODE"] != "false"
  config.send_environment = ENV["BUGSNAG_SEND_ENVIRONMENT"] == "true"
  config.meta_data_filters << 'filtered_parameter'

  if ENV["SQL_ONLY_BREADCRUMBS"] == "true"
    config.before_breadcrumb_callbacks << Proc.new do |breadcrumb|
      breadcrumb.ignore! unless breadcrumb.meta_data[:event_name] == "sql.active_record" && breadcrumb.meta_data[:name] == "User Load"
    end
  end

  if ENV["ADD_ON_ERROR"] == "true"
    config.add_on_error(proc do |report|
      report.add_tab(:on_error, {
        source: report.unhandled ? 'on_error unhandled' : 'on_error handled'
      })
    end)
  end
end
