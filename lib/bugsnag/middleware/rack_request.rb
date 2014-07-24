module Bugsnag::Middleware
  class RackRequest
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      if notification.request_data[:rack_env]
        env = notification.request_data[:rack_env]

        request = ::Rack::Request.new(env)

        params = request.params rescue {}

        session = env["rack.session"]

        # Set the context
        notification.context = "#{request.request_method} #{request.path}"

        # Set a sensible default for user_id
        notification.user_id = request.ip

        # Build the clean url (hide the port if it is obvious)
        url = "#{request.scheme}://#{request.host}"
        url << ":#{request.port}" unless [80, 443].include?(request.port)
        url << Bugsnag::Helpers.cleanup_url(request.fullpath, notification.configuration.params_filters)

        # Add a request tab
        notification.add_tab(:request, {
          :url => url,
          :httpMethod => request.request_method,
          :params => params.to_hash,
          :userAgent => request.user_agent,
          :referer => request.referer,
          :clientIp => request.ip
        })

        # Add an environment tab
        notification.add_tab(:environment, env)

        # Add a session tab
        notification.add_tab(:session, session) if session

        # Add a cookies tab
        cookies = request.cookies
        notification.add_tab(:cookies, cookies) if cookies
      end

      @bugsnag.call(notification)
    end
  end
end
