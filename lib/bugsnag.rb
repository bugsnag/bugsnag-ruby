require "rubygems"

require "bugsnag/version"
require "bugsnag/configuration"
require "bugsnag/notification"

require "bugsnag/rack"
require "bugsnag/railtie" if defined?(Rails::Railtie)

module Bugsnag
  LOG_PREFIX = "** [Bugsnag] "

  class << self
    def configure
      yield(configuration)      
      log "Bugsnag exception handler #{VERSION} ready, api_key=#{configuration.api_key}" if configuration.api_key
    end

    def notify(exception, session_data={})
      opts = {
        :releaseStage => configuration.release_stage,
        :projectRoot => configuration.project_root.to_s,
        :appVersion => configuration.app_version
      }.merge(session_data)
      
      puts "SESSION DATA " + session_data.inspect
      puts "OPTS " + opts.inspect

      # Send the notification
      notification = Notification.new(configuration.api_key, exception, opts)
      notification.send
    end

    def log(message)
      configuration.logger.info(LOG_PREFIX + message) if configuration.logger
    end

    def configuration
      @configuration ||= Bugsnag::Configuration.new
    end
  end
end