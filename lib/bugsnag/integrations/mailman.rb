require 'mailman'

module Bugsnag
  ##
  # Extracts and appends mailman message information to error reports
  class Mailman

    FRAMEWORK_ATTRIBUTES = {
      :framework => "Mailman"
    }

    def initialize
      Bugsnag.configuration.internal_middleware.use(Bugsnag::Middleware::Mailman)
      Bugsnag.configuration.detected_app_type = "mailman"
      Bugsnag.configuration.runtime_versions["mailman"] = ::Mailman::VERSION
    end

    ##
    # Calls the mailman middleware.
    def call(mail)
      begin
        Bugsnag.configuration.set_request_data :mailman_msg, mail.to_s
        yield
      rescue Exception => exception
        Bugsnag.notify(exception, true) do |report|
          report.severity = "error"
          report.severity_reason = {
            :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
            :attributes => FRAMEWORK_ATTRIBUTES
          }
        end

        # Skip this exception in future notify calls; Mailman doesn't rescue
        # uncaught exception and so this exception may end up being double
        # reported by our 'on_exit' hook
        exception.instance_eval do
          def skip_bugsnag
            true
          end
        end

        raise exception
      ensure
        Bugsnag.configuration.clear_request_data
      end
    end
  end
end


if Mailman.config.respond_to?(:middleware)
  Mailman.config.middleware.add ::Bugsnag::Mailman
end
