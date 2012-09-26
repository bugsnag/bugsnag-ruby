module Bugsnag::Middleware
  class Rails2Request
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end
      
    def call(request_data, exception, notification)
      if request_data[:rails2_request]
        request = request_data[:rails2_request]
        params = request.parameters || {}

        # Set the context
        notification.context = "#{params[:controller]}##{params[:action]}"

        # Build the clean url
        url = "#{request.protocol}#{request.host}"
        url << ":#{request.port}" unless [80, 443].include?(request.port)
        url << request.fullpath

        # Add a request tab
        notification.add_tab(:request, {
          :url => url,
          :params => params.to_hash,
          :controller => params[:controller],
          :action => params[:action]
        })

        # Add an environment tab
        notification.add_tab(:environment, request.env) if request.env

        # Add a session tab
        session_data = request.session.respond_to?(:to_hash) ? request.session.to_hash : request.session.data
        notification.add_tab(:session, session_data) if session_data

        # Add a cookies tab
        notification.add_tab(:cookies, request.cookies) if request.cookies
      end

      @bugsnag.call(request_data, exception, notification)
    end
  end
end
