module Bugsnag
  class Mailman
    def call(mail)
      begin
        yield
      rescue => ex
        Bugsnag.notify(ex)
        raise
      ensure
        Bugsnag.clear_request_data
      end
    end
  end
end

Mailman.config.middleware.add ::Bugsnag::Mailman