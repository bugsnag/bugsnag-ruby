require 'sidekiq'

module Bugsnag
  ##
  # Extracts and attaches Sidekiq job and queue information to an error report
  class Sidekiq

    FRAMEWORK_ATTRIBUTES = {
      :framework => "Sidekiq"
    }

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
        raise ex if [Interrupt, SystemExit, SignalException].include? ex.class
        notify(ex)
        raise
      ensure
        Bugsnag.configuration.clear_request_data
      end
    end

    def notify(exception)
      Bugsnag.notify(exception, true) do |report|
        report.severity = "error"
        report.severity_reason = {
          :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
          :attributes => FRAMEWORK_ATTRIBUTES
        }
      end
    end
  end
end

::Sidekiq.configure_server do |config|
  if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('3.0.0')
    config.error_handlers << proc do |ex,context|
      bugsnag_handler = ::Bugsnag::Sidekiq.new
      bugsnag_handler.notify(ex)
    end
  else
    config.server_middleware do |chain|
      chain.add ::Bugsnag::Sidekiq
    end
  end
end
