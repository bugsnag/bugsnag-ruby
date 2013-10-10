module Bugsnag
  class Mailman
    def call(mail)
      begin
        yield
      rescue => ex
        Bugsnag.notify(ex, :mailman => {"message" => mail.to_s})
        raise
      ensure
        Bugsnag.clear_request_data
      end
    end
  end
end

Mailman.config.middleware.add ::Bugsnag::Mailman if Mailman.config.respond_to?(:middleware)