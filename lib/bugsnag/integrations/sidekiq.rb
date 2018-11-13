require 'sidekiq'

module Bugsnag
  ##
  # Extracts and attaches Sidekiq job and queue information to an error report
  class Sidekiq

    unless const_defined?(:FRAMEWORK_ATTRIBUTES)
      FRAMEWORK_ATTRIBUTES = {
        :framework => "Sidekiq"
      }
    end

    def initialize
      Bugsnag.configuration.internal_middleware.use(Bugsnag::Middleware::Sidekiq)
      Bugsnag.configuration.app_type = "sidekiq"
      Bugsnag.configuration.default_delivery_method = :synchronous
    end

    def call(worker, msg, queue)
      begin
        # store msg/queue in thread local state to be read by Bugsnag::Middleware::Sidekiq
        Bugsnag.configuration.set_request_data :sidekiq, { :msg => msg, :queue => queue }
        yield
      rescue Exception => ex
        self.class.notify(ex) unless self.class.sidekiq_supports_error_handlers
        raise
      ensure
        Bugsnag.configuration.clear_request_data unless self.class.sidekiq_supports_error_handlers
      end
    end

    def self.notify(exception)
      return if [Interrupt, SystemExit, SignalException].include? exception.class
      Bugsnag.notify(exception, true) do |report|
        report.severity = "error"
        report.severity_reason = {
          :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
          :attributes => FRAMEWORK_ATTRIBUTES
        }
      end
    end

    def self.sidekiq_supports_error_handlers
      Gem::Version.new(::Sidekiq::VERSION) >= Gem::Version.new('3.0.0')
    end

    def self.configure_server(server)
      if Bugsnag::Sidekiq.sidekiq_supports_error_handlers
        server.error_handlers << proc do |ex, _context|
          Bugsnag::Sidekiq.notify(ex)
          Bugsnag.configuration.clear_request_data
        end
      end

      server.server_middleware do |chain|
        chain.add ::Bugsnag::Sidekiq
      end
    end
  end
end

::Sidekiq.configure_server do |config|
  Bugsnag::Sidekiq.configure_server(config)
end
