module Bugsnag
  module Rails
    module ActionControllerRescue
      def self.included(base)
        base.send(:alias_method, :rescue_action_in_public_without_bugsnag, :rescue_action_in_public)
        base.send(:alias_method, :rescue_action_in_public, :rescue_action_in_public_with_bugsnag)

        base.send(:alias_method, :rescue_action_locally_without_bugsnag, :rescue_action_locally)
        base.send(:alias_method, :rescue_action_locally, :rescue_action_locally_with_bugsnag)

        base.send(:before_filter, :initialize_bugsnag_request)
        # TODO: Clean up per-request stuff
      end

      private
      def initialize_bugsnag_request
        # Set up the callback for extracting the rack request data
        # This callback is only excecuted when Bugsnag.notify is called
        Bugsnag.before_notify = lambda {
          # Get session data
          session_data = session.respond_to?(:to_hash) ? session.to_hash : session.data
          session_id = session_data[:session_id] || session_data["session_id"]

          # Get current url
          url = "#{request.protocol}#{request.host}"
          url << ":#{request.port}" unless [80, 443].include?(request.port)
          url << request.fullpath

          # Automatically set user_id and context if possible
          Bugsnag.request_configuration.user_id ||= session_id
          Bugsnag.request_configuration.context ||= Bugsnag::Helpers.param_context(params)

          # Fill in the request meta-data
          Bugsnag.request_configuration.meta_data[:request] = {
              :url => url,
              :controller => params[:controller],
              :action => params[:action],
              :params => params.to_hash,
            }
          Bugsnag.request_configuration.meta_data[:session] = session_data
          Bugsnag.request_configuration.meta_data[:environment] = request.env
        }
      end

      def rescue_action_in_public_with_bugsnag(exception)
        Bugsnag.auto_notify(exception)
        rescue_action_in_public_without_bugsnag(exception)
      end

      def rescue_action_locally_with_bugsnag(exception)
        Bugsnag.auto_notify(exception)
        rescue_action_locally_without_bugsnag(exception)
      end
    end
  end
end