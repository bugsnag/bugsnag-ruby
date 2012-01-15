require "rubygems"

require "bugsnag/version"
require "bugsnag/configuration"
require "bugsnag/notification"
require "bugsnag/helpers"

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
      notification = Notification.new(exception, configuration.merge(session_data))
      notification.deliver unless notification.ignore?
    end

    def log(message)
      configuration.logger.info(LOG_PREFIX + message) if configuration.logger
    end

    def configuration
      @configuration ||= Bugsnag::Configuration.new
    end
  end
end