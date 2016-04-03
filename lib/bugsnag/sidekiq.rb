require 'sidekiq'

module Bugsnag
  class Sidekiq
    def call(worker, msg, queue)
      begin

        # store msg/queue in thread local state to be read by Bugsnag::Middleware::Sidekiq
        Bugsnag.set_request_data :sidekiq, { :msg => msg, :queue => queue }

        yield
      rescue Exception => ex
        raise ex if [Interrupt, SystemExit, SignalException].include? ex.class
        Bugsnag.auto_notify(ex)
        raise
      ensure
        Bugsnag.clear_request_data
      end
    end
  end
end

if ::Sidekiq::VERSION < '3'
  ::Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      chain.add ::Bugsnag::Sidekiq
    end
  end
else
  ::Sidekiq.configure_server do |config|
    config.error_handlers << lambda do |ex, ctx|
      Bugsnag.auto_notify(ex, :sidekiq => ctx, :context => "sidekiq##{ctx['queue']}")
    end
  end
end

# Only include if running under Sidekiq server; if it is included with Rails (for example)
# it will cause Bugsnag to crash during middleware calls and no meta-data will be sent
# along with application traces sent to the server.
if ::Sidekiq.server?
  Bugsnag.configuration.internal_middleware.use(Bugsnag::Middleware::Sidekiq)
  Bugsnag.configuration.app_type = "sidekiq"
end
