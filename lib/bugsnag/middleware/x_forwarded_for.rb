module Bugsnag::Middleware
  class XForwardedFor
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      if notification.user_id
        notification.headers['X-Forwarded-For'] = notification.user[:id]
      end
      @bugsnag.call(notification)
    end
  end
end
