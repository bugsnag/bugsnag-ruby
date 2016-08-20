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

require "bugsnag/integrations/rack"
require "bugsnag/integrations/railtie" if defined?(Rails::Railtie)

require "bugsnag/middleware/rack_request"
require "bugsnag/middleware/warden_user"
require "bugsnag/middleware/callbacks"
require "bugsnag/middleware/rails3_request"
require "bugsnag/middleware/sidekiq"
require "bugsnag/middleware/mailman"
require "bugsnag/middleware/rake"
require "bugsnag/middleware/callbacks"

module Bugsnag
  LOCK = Mutex.new

  class << self
    # Configure the Bugsnag notifier application-wide settings.
    def configure
      yield(configuration) if block_given?
    end

    # Explicitly notify of an exception
    def notify(exception, auto_notify=false, &block)
      return unless configuration.valid_api_key? && configuration.should_notify_release_stage?

      report = Report.new(exception, configuration)
      return if report.ignore?

      # Run internal middleware
      configuration.internal_middleware.run(report)
      return if report.ignore?

      # If this is an auto_notify we yield the block before the user's middleware is run
      # so that they get to see the final copy of the report there
      yield(report) if block_given? && auto_notify
      return if report.ignore?

      # Apply the user's information attached to the exceptions
      exceptions.each do |exception|
        if exception.class.include?(Bugsnag::MetaData)
          if exception.bugsnag_user_id.is_a?(String)
            self.user_id = exception.bugsnag_user_id
          end
          if exception.bugsnag_context.is_a?(String)
            self.context = exception.bugsnag_context
          end
        end
      end

      # Run users middleware
      configuration.middleware.run(report) do
        return if report.ignore?

        # If this is not an auto_notify then the block was provided by the user. This should be the last
        # block that is run as it is the users "most specific" block.
        yield(report) if block_given? && !auto_notify
        return if report.ignore?

        # Deliver
        configuration.info("Notifying #{configuration.endpoint} of #{exceptions.last.class}")
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

[:resque, :sidekiq, :mailman, :delayed_job].each do |integration|
  begin
    require "bugsnag/integrations/#{integration}"
  rescue LoadError
  end
end
