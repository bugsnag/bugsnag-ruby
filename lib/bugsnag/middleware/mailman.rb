module Bugsnag::Middleware
  class Mailman
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      notification.add_tab(:mailman, {"message" => notification.request_data[:mailman_msg]})
      @bugsnag.call(notification)
    end
  end
end
