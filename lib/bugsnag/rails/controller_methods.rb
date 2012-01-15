module Bugsnag
  module Rails
    module ControllerMethods
      private
      def notify_bugsnag(exception, custom_data=nil)
        unless bugsnag_local_request?
          request_data = bugsnag_request_data
          request_data[:metaData][:custom] = custom_data if custom_data
          Bugsnag.notify(exception, request_data)
        end
      end

      def bugsnag_request_data
        {
          :userId => bugsnag_session_id,
          :context => bugsnag_context,
          :metaData => {
            :request => {
              :url => bugsnag_request_url,
              :controller => params[:controller],
              :action => params[:action],
              :params => bugsnag_filter_if_filtering(params.to_hash),
            },
            :session => bugsnag_filter_if_filtering(bugsnag_session_data),
            :environment => bugsnag_filter_if_filtering(bugsnag_environment)
          }
        }
      end

      def bugsnag_local_request?
        if defined?(::Rails.application.config)
          ::Rails.application.config.consider_all_requests_local || request.local?
        else
          consider_all_requests_local || local_request?
        end
      end

      def bugsnag_session_id
        session = bugsnag_session_data
        session[:session_id] || session["session_id"]
      end
      
      def bugsnag_context
        "#{params[:controller]}##{params[:action]}"
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
    
      def bugsnag_environment
        request.env.inject({}) do |hash, (k, v)|
          hash[k.gsub(/\./, "-")] = v.to_s
          hash
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