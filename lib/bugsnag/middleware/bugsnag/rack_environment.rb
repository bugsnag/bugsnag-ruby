module Bugsnag
  module Middleware
    class RackEnvironment
      def initialize(bugsnag)
        @bugsnag = bugsnag
      end
      
      def call(request_data, exception, notification)
        if request_data[:rack_env]
          notification.add_tab :environment, request_data[:rack_env]
        end
        @bugsnag.call(request_data, exception, notification)
      end
    end
  end
end
