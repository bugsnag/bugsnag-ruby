require 'sidekiq'

module Bugsnag
  class Sidekiq
    def initialize
      Bugsnag.configuration.internal_middleware.use(Bugsnag::Middleware::Sidekiq)
      Bugsnag.configuration.app_type = "sidekiq"
      Bugsnag.configuration.default_delivery_method = :synchronous
    end

    def call(worker, msg, queue)
      begin
        # store msg/queue in thread local state to be read by Bugsnag::Middleware::Sidekiq
        Bugsnag.set_request_data :sidekiq, { :msg => msg, :queue => queue }

        yield
      rescue Exception => ex
        raise ex if [Interrupt, SystemExit, SignalException].include? ex.class
        Bugsnag.auto_notify(ex, {
          :severity_reason => {
            :type => Bugsnag::Notification::UNHANDLED_EXCEPTION_MIDDLEWARE,
            :attributes => {
              :framework => "Sidekiq"
            }
          }
        })
        raise
      ensure
        Bugsnag.clear_request_data
      end
    end
  end
end

::Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('3.3.0')
      chain.prepend ::Bugsnag::Sidekiq
    else
      chain.add ::Bugsnag::Sidekiq
    end
  end
end
