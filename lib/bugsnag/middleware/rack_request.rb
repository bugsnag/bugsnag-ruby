module Bugsnag::Middleware
  class RackRequest
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end
      
    def call(request_data, exception, notification)
      if request_data[:rack_env]
        env = request_data[:rack_env]
        request = ::Rack::Request.new(env)
        params = request.params

        # Set the context
        notification.context = "#{request.request_method} #{request.path}"

        # TODO: set notification.user_id to a sensible default

        # Build the clean url (hide the port if it is obvious)
        url = "#{request.scheme}://#{request.host}"
        url << ":#{request.port}" unless [80, 443].include?(request.port)
        url << request.fullpath

        # Add a request tab
        notification.add_tab(:request, {
          :url => url,
          :params => params.to_hash,
          :userAgent => request.user_agent,
          :clientIp => request.ip
        })
          
        # Add an environment tab
        notification.add_tab(:environment, env)

        # Add a session tab
        session = env["rack.session"]
        notification.add_tab(:session, session) if session

        # Add a cookies tab
        cookies = request.cookies
        notification.add_tab(:cookies, cookies) if cookies
      end

      @bugsnag.call(request_data, exception, notification)
    end
  end
end
