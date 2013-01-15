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

        # Add the rails version
        notification.add_tab(:environment, {
          :railsVersion => Rails::VERSION::STRING
        })
      end

      @bugsnag.call(notification)
    end
  end
end
