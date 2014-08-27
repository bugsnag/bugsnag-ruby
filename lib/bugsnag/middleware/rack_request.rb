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
        # Load session for Rails (for Rails 4 it's lazy loaded).
        # @see https://github.com/rails/rails/issues/10813
        session["session_id"]

        notification.context = "#{request.request_method} #{request.path}"

        # Set a sensible default for user_id
        notification.user_id = request.ip

        # Build the clean url (hide the port if it is obvious)
        url = "#{request.scheme}://#{request.host}"
        url << ":#{request.port}" unless [80, 443].include?(request.port)
        url << Bugsnag::Helpers.cleanup_url(request.fullpath, notification.configuration.params_filters)

        notification.add_tab(:request, {
          :url => url,
          :httpMethod => request.request_method,
          :params => params.to_hash,
          :userAgent => request.user_agent,
          :referer => request.referer,
          :clientIp => request.ip
        })

        notification.add_tab(:environment, env)

        if session
          # Rails 3
          if session.is_a?(Hash)
            notification.add_tab(:session, session)
          else
            # Rails 4
            notification.add_tab(:session, session.to_hash)
          end
        end

        cookies = request.cookies
        notification.add_tab(:cookies, cookies) if cookies
      end

      @bugsnag.call(notification)
    end
  end
end
