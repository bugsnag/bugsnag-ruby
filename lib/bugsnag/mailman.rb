require 'mailman'

module Bugsnag
  class Mailman
    def call(mail)
      begin

        Bugsnag.set_request_data :mailman_msg, mail.to_s

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


if Mailman.config.respond_to?(:middleware)
  Mailman.config.middleware.add ::Bugsnag::Mailman
end

Bugsnag.configuration.internal_middleware.use(Bugsnag::Middleware::Mailman)
Bugsnag.configuration.app_type = "mailman"
