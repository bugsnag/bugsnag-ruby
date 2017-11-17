require "rubygems"
require "thread"

require "bugsnag/version"
require "bugsnag/configuration"
require "bugsnag/meta_data"
require "bugsnag/report"
require "bugsnag/cleaner"
require "bugsnag/helpers"

require "bugsnag/delivery"
require "bugsnag/delivery/synchronous"
require "bugsnag/delivery/thread_queue"

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

  class << self
    # Configure the Bugsnag notifier application-wide settings.
    def configure
      yield(configuration) if block_given?

      @key_warning = false unless defined?(@key_warning)
      if !configuration.valid_api_key? && !@key_warning
        configuration.warn("No valid API key has been set, notifications will not be sent")
        @key_warning = true
      end
    end

    # Explicitly notify of an exception
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
        payload_string = ::JSON.dump(Bugsnag::Helpers.trim_if_needed(report.as_json))
        Bugsnag::Delivery[configuration.delivery_method].deliver(configuration.endpoint, payload_string, configuration)
      end
    end

    # Configuration getters
    def configuration
      @configuration = nil unless defined?(@configuration)
      @configuration || LOCK.synchronize { @configuration ||= Bugsnag::Configuration.new }
    end

    # Allow access to "before notify" callbacks
    def before_notify_callbacks
      Bugsnag.configuration.request_data[:before_callbacks] ||= []
    end
  end
end

require "bugsnag/integrations/railtie" if defined?(Rails::Railtie)
[:resque, :sidekiq, :mailman, :delayed_job, :shoryuken, :que].each do |integration|
  begin
    require "bugsnag/integrations/#{integration}"
  rescue LoadError
  end
end
