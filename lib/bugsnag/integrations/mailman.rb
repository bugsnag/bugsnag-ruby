require 'mailman'

module Bugsnag
  class Mailman
    def initialize
      Bugsnag.configuration.internal_middleware.use(Bugsnag::Middleware::Mailman)
      Bugsnag.configuration.app_type = "mailman"
    end

    def call(mail)
      begin
        Bugsnag.configuration.set_request_data :mailman_msg, mail.to_s
        yield
      rescue Exception => ex
        raise ex if [Interrupt, SystemExit, SignalException].include? ex.class
        Bugsnag.auto_notify(ex, {
            :type => "middleware",
            :attributes => {
              :name => "mailman"
            }
          }) do |report|
          report.severity = "error"
        end
        raise
      ensure
        Bugsnag.configuration.clear_request_data
      end
    end
  end
end


if Mailman.config.respond_to?(:middleware)
  Mailman.config.middleware.add ::Bugsnag::Mailman
end
