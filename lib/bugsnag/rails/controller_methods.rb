module Bugsnag
  module Rails
    module ControllerMethods
      private
      def notify_bugsnag(exception, custom_data=nil)
        request_data = bugsnag_request_data
        request_data[:meta_data][:custom] = custom_data if custom_data
        Bugsnag.notify(exception, request_data)
      end

      def bugsnag_request_data
        {
          :user_id => bugsnag_session_id,
          :context => Bugsnag::Helpers.param_context(params),
          :meta_data => {
            :request => {
              :url => bugsnag_request_url,
              :controller => params[:controller],
              :action => params[:action],
              :params => bugsnag_filter_if_filtering(params.to_hash),
            },
            :session => bugsnag_filter_if_filtering(Bugsnag::Helpers.cleanup_hash(bugsnag_session_data),
            :environment => bugsnag_filter_if_filtering(Bugsnag::Helpers.cleanup_hash(request.env))
          }
        }
      end

      def bugsnag_session_id
        session = bugsnag_session_data
        session[:session_id] || session["session_id"]
      end
      
      def bugsnag_request_url
        url = "#{request.protocol}#{request.host}"

        unless [80, 443].include?(request.port)
          url << ":#{request.port}"
        end

        url << request.fullpath
        url
      end

      def bugsnag_session_data
        if session.respond_to?(:to_hash)
          session.to_hash
        else
          session.data
        end
      end
    
      def bugsnag_filter_if_filtering(hash)
        return hash if ! hash.is_a?(Hash)

        if respond_to?(:filter_parameters)
          filter_parameters(hash) rescue hash
        else
          hash
        end
      end

    end
  end
end