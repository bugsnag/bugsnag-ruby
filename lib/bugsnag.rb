require "rubygems"
require "thread"

require "bugsnag/version"
require "bugsnag/configuration"
require "bugsnag/meta_data"
require "bugsnag/report"
require "bugsnag/cleaner"
require "bugsnag/helpers"
require "bugsnag/session_tracker"

require "bugsnag/delivery"
require "bugsnag/delivery/synchronous"
require "bugsnag/delivery/thread_queue"

# Rack is not bundled with the other integrations
# as it doesn't auto-configure when loaded
require "bugsnag/integrations/rack"

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
  LOCK = Mutex.new
  INTEGRATIONS = [:resque, :sidekiq, :mailman, :delayed_job, :shoryuken, :que]

  class << self
    ##
    # Configure the Bugsnag notifier application-wide settings.
    #
    # Yields a configuration object to use to set application settings.
    def configure(validate_api_key=true)
      yield(configuration) if block_given?

      check_key_valid if validate_api_key
    end

    ##
    # Explicitly notify of an exception.
    #
    # Optionally accepts a block to append metadata to the yielded report.
    def notify(exception, auto_notify=false, &block)
      unless auto_notify.is_a? TrueClass or auto_notify.is_a? FalseClass
        configuration.warn("Adding metadata/severity using a hash is no longer supported, please use block syntax instead")
        auto_notify = false
      end

      if !configuration.auto_notify && auto_notify
        configuration.debug("Not notifying because auto_notify is disabled")
        return
      end

      if !configuration.valid_api_key?
        configuration.debug("Not notifying due to an invalid api_key")
        return
      end

      if !configuration.should_notify_release_stage?
        configuration.debug("Not notifying due to notify_release_stages :#{configuration.notify_release_stages.inspect}")
        return
      end

      if exception.respond_to?(:skip_bugsnag) && exception.skip_bugsnag
        configuration.debug("Not notifying due to skip_bugsnag flag")
        return
      end

      report = Report.new(exception, configuration, auto_notify)

      # If this is an auto_notify we yield the block before the any middleware is run
      yield(report) if block_given? && auto_notify
      if report.ignore?
        configuration.debug("Not notifying #{report.exceptions.last[:errorClass]} due to ignore being signified in auto_notify block")
        return
      end

      # Run internal middleware
      configuration.internal_middleware.run(report)
      if report.ignore?
        configuration.debug("Not notifying #{report.exceptions.last[:errorClass]} due to ignore being signified in internal middlewares")
        return
      end

      # Store before_middleware severity reason for future reference
      initial_severity = report.severity
      initial_reason = report.severity_reason

      # Run users middleware
      configuration.middleware.run(report) do
        if report.ignore?
          configuration.debug("Not notifying #{report.exceptions.last[:errorClass]} due to ignore being signified in user provided middleware")
          return
        end

        # If this is not an auto_notify then the block was provided by the user. This should be the last
        # block that is run as it is the users "most specific" block.
        yield(report) if block_given? && !auto_notify
        if report.ignore?
          configuration.debug("Not notifying #{report.exceptions.last[:errorClass]} due to ignore being signified in user provided block")
          return
        end

        # Test whether severity has been changed and ensure severity_reason is consistant in auto_notify case
        if report.severity != initial_severity
          report.severity_reason = {
            :type => Report::USER_CALLBACK_SET_SEVERITY
          }
        else
          report.severity_reason = initial_reason
        end

        # Deliver
        configuration.info("Notifying #{configuration.endpoint} of #{report.exceptions.last[:errorClass]}")
        options = {:headers => report.headers}
        payload = ::JSON.dump(Bugsnag::Helpers.trim_if_needed(report.as_json))
        Bugsnag::Delivery[configuration.delivery_method].deliver(configuration.endpoint, payload, configuration, options)
      end
    end

    ##
    # Returns the client's Configuration object, or creates one if not yet created.
    def configuration
      @configuration = nil unless defined?(@configuration)
      @configuration || LOCK.synchronize { @configuration ||= Bugsnag::Configuration.new }
    end

    ##
    # Returns the client's SessionTracker object, or creates one if not yet created.
    def session_tracker
      @session_tracker = nil unless defined?(@session_tracker)
      @session_tracker || LOCK.synchronize { @session_tracker ||= Bugsnag::SessionTracker.new}
    end

    ##
    # Starts a session.
    #
    # Allows Bugsnag to track error rates across releases.
    def start_session
      session_tracker.start_session
    end

    ##
    # Allow access to "before notify" callbacks as an array.
    #
    # These callbacks will be called whenever an error notification is being made.
    def before_notify_callbacks
      Bugsnag.configuration.request_data[:before_callbacks] ||= []
    end

    # Attempts to load all integrations through auto-discovery
    def load_integrations
      require "bugsnag/integrations/railtie" if defined?(Rails::Railtie)
      INTEGRATIONS.each do |integration|
        begin
          require "bugsnag/integrations/#{integration}"
        rescue LoadError
        end
      end
    end

    # Load a specific integration
    def load_integration(integration)
      integration = :railtie if integration == :rails
      if INTEGRATIONS.include?(integration) || integration == :railtie
        require "bugsnag/integrations/#{integration}"
      else
        configuration.debug("Integration #{integration} is not currently supported")
      end
    end

    # Check if the API key is valid and warn (once) if it is not
    def check_key_valid
      @key_warning = false unless defined?(@key_warning)
      if !configuration.valid_api_key? && !@key_warning
        configuration.warn("No valid API key has been set, notifications will not be sent")
        @key_warning = true
      end
    end
  end
end

Bugsnag.load_integrations unless ENV["BUGSNAG_DISABLE_AUTOCONFIGURE"]
