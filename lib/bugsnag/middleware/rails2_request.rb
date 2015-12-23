module Bugsnag::Middleware
  class Rails2Request
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      if notification.request_data[:rails2_request]
        request = notification.request_data[:rails2_request]
        params = request.parameters || {}
        session_data = request.session.respond_to?(:to_hash) ? request.session.to_hash : request.session.data

        # Set the context
        notification.context = "#{params[:controller]}##{params[:action]}"

        # Set a sensible default for user_id
        notification.user_id = request.remote_ip if request.respond_to?(:remote_ip)

        # Build the clean url
        url = "#{request.protocol}#{request.host}"
        url << ":#{request.port}" unless [80, 443].include?(request.port)
        url << Bugsnag::Cleaner.new(notification.configuration.params_filters).clean_url(request.fullpath)

        # Add a request tab
        notification.add_tab(:request, {
          :url => url,
          :params => params.to_hash,
          :controller => params[:controller],
          :action => params[:action]
        })

        # Add an environment tab
        if request.env && notification.configuration.send_environment
          notification.add_tab(:environment, request.env)
        end

        # Add a session tab
        notification.add_tab(:session, session_data) if session_data

        # Add a cookies tab
        notification.add_tab(:cookies, request.cookies) if request.cookies

        # Add the rails version
        notification.add_tab(:environment, {
          :railsVersion => Rails::VERSION::STRING
        })
      end

      @bugsnag.call(notification)
    end
  end
end
