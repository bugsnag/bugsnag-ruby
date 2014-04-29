require "rubygems"

require "bugsnag/version"
require "bugsnag/configuration"
require "bugsnag/meta_data"
require "bugsnag/notification"
require "bugsnag/helpers"
require "bugsnag/deploy"

require "bugsnag/rack"
require "bugsnag/railtie" if defined?(Rails::Railtie)

[:resque, :sidekiq, :mailman, :delayed_job].each do |integration|
  begin
    require "bugsnag/#{integration}"
  rescue LoadError
  end
end

module Bugsnag
  LOG_PREFIX = "** [Bugsnag] "

  class << self
    # Configure the Bugsnag notifier application-wide settings.
    def configure(config_hash=nil)
      if config_hash
        config_hash.each do |k,v|
          configuration.send("#{k}=", v) rescue nil if configuration.respond_to?("#{k}=")
        end
      end

      yield(configuration) if block_given?

      # Use resque for asynchronous notification if required
      require "bugsnag/delay/resque" if configuration.delay_with_resque && defined?(Resque)

      # Log that we are ready to rock
      if configuration.api_key && !@logged_ready
        log "Bugsnag exception handler #{VERSION} ready, api_key=#{configuration.api_key}"
        @logged_ready = true
      end
    end

    # Explicitly notify of an exception
    def notify(exception, overrides=nil, request_data=nil)
      Notification.new(exception, configuration, overrides, request_data).deliver
    end

    # Notify of an exception unless it should be ignored
    def notify_or_ignore(exception, overrides=nil, request_data=nil)
      notification = Notification.new(exception, configuration, overrides, request_data)

      unless notification.ignore?
        notification.deliver
        notification
      else
        false
      end
    end

    # Auto notify of an exception, called from rails and rack exception
    # rescuers, unless auto notification is disabled, or we should ignore this
    # error class
    def auto_notify(exception, overrides=nil, request_data=nil)
      overrides ||= {}
      overrides.merge!({:severity => "fatal"})
      notify_or_ignore(exception, overrides, request_data) if configuration.auto_notify
    end

    # Log wrapper
    def log(message)
      configuration.logger.info("#{LOG_PREFIX}#{message}")
    end

    # Warning logger
    def warn(message)
      configuration.logger.warn("#{LOG_PREFIX}#{message}")
    end

    # Debug logger
    def debug(message)
      configuration.logger.info("#{LOG_PREFIX}#{message}") if configuration.debug
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
