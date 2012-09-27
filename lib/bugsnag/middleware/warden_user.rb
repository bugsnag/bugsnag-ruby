module Bugsnag::Middleware
  class WardenUser
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(request_data, exception, notification)
      if request_data[:rack_env]
        env = request_data[:rack_env]
        session = env["rack.session"] || {}

        # Set an actual user_id from warden
        if session["warden.user.user.key"]
          begin
            notification.user_id = session["warden.user.user.key"][1][0]
          rescue; end
        end
      end

      @bugsnag.call(request_data, exception, notification)
    end
  end
end