require 'sidekiq'

module Bugsnag
  class Sidekiq
    def call(worker, msg, queue)
      begin
        Bugsnag.before_notify_callbacks << lambda {|notif|
          notif.add_tab(:sidekiq, msg)
          notif.context ||= "sidekiq##{queue}"
        }

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

::Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add ::Bugsnag::Sidekiq
  end
end
