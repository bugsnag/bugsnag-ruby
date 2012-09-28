require "rubygems"

require "bugsnag/version"
require "bugsnag/configuration"
require "bugsnag/notification"
require "bugsnag/helpers"

require "bugsnag/rack"
require "bugsnag/railtie" if defined?(Rails::Railtie)

require "resque/failure/bugsnag" if defined?(Resque)

module Bugsnag
  LOG_PREFIX = "** [Bugsnag] "

  class << self
    # Configure the Bugsnag notifier application-wide settings.
    def configure
      yield(configuration)

      # Log that we are ready to rock
      if configuration.api_key && !@logged_ready
        log "Bugsnag exception handler #{VERSION} ready, api_key=#{configuration.api_key}" 
        @logged_ready = true
      end
    end

    # Explicitly notify of an exception
    def notify(exception, overrides={})
      Notification.new(exception, configuration, overrides).deliver
    end

    # Notify of an exception unless it should be ignored
    def notify_or_ignore(exception, overrides={})
      notification = Notification.new(exception, configuration, overrides)
      notification.deliver unless notification.ignore?
    end

    # Auto notify of an exception, called from rails and rack exception 
    # rescuers, unless auto notification is disabled, or we should ignore this
    # error class
    def auto_notify(exception, overrides={})
      notify_or_ignore(exception, overrides) if configuration.auto_notify
    end

    # Log wrapper
    def log(message)
      configuration.logger.info(LOG_PREFIX + message) if configuration.logger
    end

    # Warning logger
    def warn(message)
      if configuration.logger
        configuration.logger.warn(LOG_PREFIX + message)
      else
        puts "#{LOG_PREFIX}#{message}"
      end
    end

    # Configuration getters
    def configuration
      @configuration ||= Bugsnag::Configuration.new
    end

    # Set "per-request" data, temporal data for use in bugsnag middleware
    def set_request_data(key, value)
      Bugsnag.configuration.set_request_data(key, value)
    end

    # Clear all "per-request" data, temporal data for use in bugsnag middleware    
    # This method should be called after each distinct request or session ends
    # Eg. After completing a page request in a web app
    def clear_request_data
      Bugsnag.configuration.clear_request_data
    end

    # Allow access to "before notify" callbacks
    def before_notify_callbacks
      Bugsnag.configuration.request_data[:before_callbacks] ||= []
    end

    # Allow access to "after notify" callbacks
    def after_notify_callbacks
      Bugsnag.configuration.request_data[:after_callbacks] ||= []
    end
  end
end