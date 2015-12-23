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
        url << Bugsnag::Cleaner.new(notification.configuration.params_filters).clean_url(request.fullpath)

        headers = {}

        env.each_pair do |key, value|
          if key.to_s.start_with?("HTTP_")
            header_key = key[5..-1]
          elsif ["CONTENT_TYPE", "CONTENT_LENGTH"].include?(key)
            header_key = key
          else
            next
          end

          headers[header_key.split("_").map {|s| s.capitalize}.join("-")] = value
        end

        # Add a request tab
        notification.add_tab(:request, {
          :url => url,
          :httpMethod => request.request_method,
          :params => params.to_hash,
          :referer => request.referer,
          :clientIp => request.ip,
          :headers => headers
        })

        # Add an environment tab
        if notification.configuration.send_environment
          notification.add_tab(:environment, env)
        end

        # Add a session tab
        if session
          if session.is_a?(Hash)
            # Rails 3
            notification.add_tab(:session, session)
          elsif session.respond_to?(:to_hash)
            # Rails 4
            notification.add_tab(:session, session.to_hash)
          end
        end
      end

      @bugsnag.call(notification)
    end
  end
end
