module Bugsnag::Middleware
  class Callbacks
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      if notification.request_data[:before_callbacks]
        notification.request_data[:before_callbacks].each {|c| c.call(*[notification][0...c.arity]) }
      end

      @bugsnag.call(notification)
    end
  end
end
