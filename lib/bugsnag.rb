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
    attr_accessor :before_notify
    
    # Configure the Bugsnag notifier application-wide settings.
    def configure
      yield(configuration)

      # Use resque for asynchronous notification if required
      require "bugsnag/delay/resque" if configuration.delay_with == :resque && defined?(Resque)

      # Log that we are ready to rock
      if configuration.api_key && !@logged_ready
        log "Bugsnag exception handler #{VERSION} ready, api_key=#{configuration.api_key}" 
        @logged_ready = true
      end
    end

    # Configure the Bugsnag notifier per-request settings.
    def configure_request
      yield(request_configuration)
    end

    # Clears the per-request settings.
    def clear_request_config
      Bugsnag::RequestConfiguration.clear_instance
    end

    # Explicitly notify of an exception
    def notify(exception, overrides={})
      Notification.new(exception, configuration, request_configuration).deliver(overrides)
    end

    # Notify of an exception unless it should be ignored
    def notify_or_ignore(exception, overrides={})
      notification = Notification.new(exception, configuration, request_configuration)
      notification.deliver(overrides) unless notification.ignore?
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

    def request_configuration
      Bugsnag::RequestConfiguration.get_instance
    end
  end
end