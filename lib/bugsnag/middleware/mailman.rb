module Bugsnag::Middleware
  class Mailman
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      mailman_msg = notification.request_data[:mailman_msg]
      notification.add_tab(:mailman, {"message" => mailman_msg}) if mailman_msg
      @bugsnag.call(notification)
    end
  end
end
