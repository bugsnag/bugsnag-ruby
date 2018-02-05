module Bugsnag::Middleware
  class Mailman

    ##
    # Extracts and attaches mailman data to the request.
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    ##
    # Executes the callback.
    def call(report)
      mailman_msg = report.request_data[:mailman_msg]
      report.add_tab(:mailman, {"message" => mailman_msg}) if mailman_msg
      @bugsnag.call(report)
    end
  end
end
