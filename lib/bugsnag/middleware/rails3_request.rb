module Bugsnag::Middleware
  class Rails3Request
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      if notification.request_data[:rack_env]
        env = notification.request_data[:rack_env]
        params = env["action_dispatch.request.parameters"]

        if params
          # Set the context
          notification.context = "#{params[:controller]}##{params[:action]}"

          # Augment the request tab
          notification.add_tab(:request, {
            :railsAction => "#{params[:controller]}##{params[:action]}",
            :params => params
          })
        end

        # Use action_dispatch.remote_ip for IP address fields and send request id
        notification.add_tab(:request, {
          :clientIp => env["action_dispatch.remote_ip"],
          :requestId => env["action_dispatch.request_id"]
        })

        notification.user_id = env["action_dispatch.remote_ip"]

        # Add the rails version
        if notification.configuration.send_environment
          notification.add_tab(:environment, {
            :railsVersion => Rails::VERSION::STRING
          })
        end
      end

      @bugsnag.call(notification)
    end
  end
end
