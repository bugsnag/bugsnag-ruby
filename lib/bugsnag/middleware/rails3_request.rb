module Bugsnag::Middleware
  class Rails3Request
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end
      
    def call(request_data, exception, notification)
      if request_data[:rack_env]
        env = request_data[:rack_env]
        params = env["action_dispatch.request.parameters"]

        # Set the context
        notification.context = "#{params[:controller]}##{params[:action]}"

        # Augment the request tab
        if params
          notification.add_tab(:request, {
            :railsAction => "#{params[:controller]}##{params[:action]}",
            :params => params
          })
        end
      end

      @bugsnag.call(request_data, exception, notification)
    end
  end
end
