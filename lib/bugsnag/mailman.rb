require 'mailman'

module Bugsnag
  class Mailman
    def call(mail)
      begin
        Bugsnag.before_notify_callbacks << lambda {|notif|
          notif.add_tab(:mailman, {"message" => mail.to_s})
        }

        yield
      rescue => ex
        raise ex if [Interrupt, SystemExit, SignalException].include? ex.class
        Bugsnag.auto_notify(ex)
        raise
      ensure
        Bugsnag.clear_request_data
      end
    end
  end
end

if Mailman.config.respond_to?(:middleware)
  Mailman.config.middleware.add ::Bugsnag::Mailman
end
