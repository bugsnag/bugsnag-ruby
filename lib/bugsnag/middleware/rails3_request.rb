module Bugsnag::Middleware
  class Rails3Request
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end
      
    def call(request_data, exception, notification)
      if request_data[:rack_env]
        env = request_data[:rack_env]
        params = env["action_dispatch.request.parameters"]

        if params
          # Add a request tab
          notification.add_tab(:request, {
            :controller => params[:controller],
            :action => params[:action],
            :params => params
          })
        end
      end

      @bugsnag.call(request_data, exception, notification)
    end
  end
end
