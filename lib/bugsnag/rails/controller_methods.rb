module Bugsnag
  module Rails
    module ControllerMethods
      private
      def notify_bugsnag(exception, meta_data=nil)
        unless bugsnag_local_request?
          Bugsnag.notify(exception, :request_data => bugsnag_request_data, :meta_data => meta_data)
        end
      end
      
      def bugsnag_local_request?
        if defined?(::Rails.application.config)
          ::Rails.application.config.consider_all_requests_local || request.local?
        else
          consider_all_requests_local || local_request?
        end
      end

      def bugsnag_request_data
        # TODO: Re-enable the env when the event-server can cope with . in keys
        env = request.env.inject({}) {|hash, (k, v) | hash[k] = v.inspect; hash}
        { :parameters       => bugsnag_filter_if_filtering(params.to_hash),
          :session_data     => bugsnag_filter_if_filtering(bugsnag_session_data),
          :controller       => params[:controller],
          :action           => params[:action],
          :url              => bugsnag_request_url,
          :cgi_data         => bugsnag_filter_if_filtering(env) }
      end

      def bugsnag_filter_if_filtering(hash)
        return hash if ! hash.is_a?(Hash)

        if respond_to?(:filter_parameters)
          filter_parameters(hash) rescue hash
        else
          hash
        end
      end

      def bugsnag_session_data
        if session.respond_to?(:to_hash)
          session.to_hash
        else
          session.data
        end
      end

      def bugsnag_request_url
        url = "#{request.protocol}#{request.host}"

        unless [80, 443].include?(request.port)
          url << ":#{request.port}"
        end

        url << request.fullpath
        url
      end
    end
  end
end