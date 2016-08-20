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
    def notify(exception, &block)
      #Build notification
      notification = Notification.new(exception, configuration)

      #Check if config allows send
      if configuration.
      #Run internal middleware
      #Run internal block?
      #Run users middleware
      #Run users block
      #Deliver

      yield(notification) if block_given?

      notification.deliver
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
