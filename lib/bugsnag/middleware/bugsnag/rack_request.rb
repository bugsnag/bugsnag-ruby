module Bugsnag
  module Middleware
    class RackRequest
      def initialize(bugsnag)
        @bugsnag = bugsnag
      end
      
      def call(request_data, exception, notification)
        if request_data[:rack_env]
          request = ::Rack::Request.new(request_data[:rack_env])
          params = request_data[:rack_env]["action_dispatch.request.parameters"] || request.params
          
          notification.context = Bugsnag::Helpers.param_context(params) || Bugsnag::Helpers.request_context(request)
          
          notification.add_tab :request, {
              :url => request.url,
              :controller => params[:controller],
              :action => params[:action],
              :params => params.to_hash
            }
        end
        @bugsnag.call(request_data, exception, notification)
      end
    end
  end
end
