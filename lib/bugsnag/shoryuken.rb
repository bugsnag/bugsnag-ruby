require 'shoryuken'

module Bugsnag
  class Shoryuken
    def initialize
      Bugsnag.configuration.app_type = "shoryuken"
      Bugsnag.configuration.default_delivery_method = :synchronous
    end

    def call(_, queue, _, body)
      begin
        Bugsnag.before_notify_callbacks << lambda {|notification|
          notification.add_tab(:shoryuken, {
            queue: queue,
            body: body
          })
        }

        yield
      rescue Exception => ex
        Bugsnag.auto_notify(ex, {
          :severity_reason => {
            :type => Bugsnag::Notification::UNHANDLED_EXCEPTION_MIDDLEWARE,
            :attributes => {
              :framework => "Shoryuken"
            }
          }
        }) unless [Interrupt, SystemExit, SignalException].include?(ex.class)
        raise
      ensure
        Bugsnag.clear_request_data
      end
    end
  end
end

::Shoryuken.configure_server do |config|
  config.server_middleware do |chain|
    chain.add ::Bugsnag::Shoryuken
  end
end
