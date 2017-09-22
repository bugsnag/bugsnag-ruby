require "rubygems"
require "thread"

require "bugsnag/version"
require "bugsnag/configuration"
require "bugsnag/meta_data"
require "bugsnag/notification"
require "bugsnag/cleaner"
require "bugsnag/helpers"
require "bugsnag/deploy"

require "bugsnag/delivery"
require "bugsnag/delivery/synchronous"
require "bugsnag/delivery/thread_queue"

require "bugsnag/rack"

require "bugsnag/middleware/rack_request"
require "bugsnag/middleware/warden_user"
require "bugsnag/middleware/clearance_user"
require "bugsnag/middleware/callbacks"
require "bugsnag/middleware/rails3_request"
require "bugsnag/middleware/sidekiq"
require "bugsnag/middleware/mailman"
require "bugsnag/middleware/rake"
require "bugsnag/middleware/callbacks"
require "bugsnag/middleware/classify_error"

module Bugsnag
  LOG_PREFIX = "** [Bugsnag] "
  LOCK = Mutex.new

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

      # Add info error classifier to internal middleware
      configuration.internal_middleware.use(Bugsnag::Middleware::ClassifyError)

      # Warn if an api_key hasn't been set
      @key_warning = false unless defined?(@key_warning)

      if !configuration.api_key && !@key_warning
        warn "No API key has been set, check your configuration"
        @key_warning = true
      end

      # Log that we are ready to rock
      @logged_ready = false unless defined?(@logged_ready)

      if configuration.api_key && !@logged_ready
        log "Bugsnag exception handler #{VERSION} ready"
        @logged_ready = true
      end
    end

    # Explicitly notify of an exception
    def notify(exception, overrides=nil, request_data=nil, &block)
      notification = Notification.new(exception, configuration, overrides, request_data)

      initial_severity = notification.severity
      initial_reason = notification.severity_reason

      yield(notification) if block_given?

      if notification.severity != initial_severity
        notification.severity_reason = {
          :type => Bugsnag::Notification::USER_CALLBACK_SET_SEVERITY
        }
      else
        notification.severity_reason = initial_reason
      end

      unless notification.ignore?
        notification.deliver
        notification
      else
        false
      end
    end
    alias_method :notify_or_ignore, :notify

    # Auto notify of an exception, called from rails and rack exception
    # rescuers, unless auto notification is disabled, or we should ignore this
    # error class
    def auto_notify(exception, overrides=nil, request_data=nil, &block)
      overrides ||= {}
      overrides[:severity] = "error" unless overrides.has_key? :severity
      overrides[:unhandled] = true unless overrides.has_key? :unhandled
      notify_or_ignore(exception, overrides, request_data, &block) if configuration.auto_notify
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
      @configuration = nil unless defined?(@configuration)
      @configuration || LOCK.synchronize { @configuration ||= Bugsnag::Configuration.new }
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

require "bugsnag/railtie" if defined?(Rails::Railtie)
[:resque, :sidekiq, :mailman, :delayed_job, :shoryuken, :que].each do |integration|
  begin
    require "bugsnag/#{integration}"
  rescue LoadError
  end
end
