module Bugsnag
  module Middleware
    class RackSession
      def initialize(bugsnag)
        @bugsnag = bugsnag
      end
      
      def call(request_data, exception, notification)
        if request_data[:rack_env]
          session = request_data[:rack_env]["rack.session"]
          
          if session
            notification.user_id ||= session[:session_id] || session["session_id"] rescue nil
          end
          
          notification.add_tab[:rack_env] :session, session
        end
        @bugsnag.call(request_data, exception, notification)
      end
    end
  end
end
