module Bugsnag::Middleware
  class RailsCallbacks
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end
      
    def call(request_data, exception, notification)
      if request_data[:rails_before_callbacks]
        request_data[:rails_before_callbacks].each {|c| c.call(notification, exception) }
      end

      @bugsnag.call(request_data, exception, notification)

      if request_data[:rails_after_callbacks]
        request_data[:rails_after_callbacks].each {|c| c.call(notification, exception) }
      end
    end
  end
end
