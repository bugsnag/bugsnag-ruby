module Bugsnag
  class Rack
    def initialize(app)
      @app = app
      if Bugsnag.configuration.project_root.nil? || Bugsnag.configuration.project_root.empty?
        if defined?(settings)
          Bugsnag.configuration.project_root = settings.root
        else
          caller.each do |c|
            if c =~ /[\/\\]config.ru$/
              Bugsnag.configuration.project_root = File.dirname(c.split(":").first)
              break
            end
          end
        end
      end
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        Bugsnag.auto_notify(raised, self.class.set_bugsnag_request_data(env))
        Bugsnag.clear_request_config
        raise
      end

      if env['rack.exception']
        Bugsnag.auto_notify(env['rack.exception'], self.class.set_bugsnag_request_data(env))
      end
      Bugsnag.clear_request_config

      response
    end

    class << self
      def set_bugsnag_request_data(env)
        request = ::Rack::Request.new(env)

        session = env["rack.session"]
        params = env["action_dispatch.request.parameters"] || request.params
        user_id = session[:session_id] || session["session_id"] if session

        Bugsnag.configure_request do |config|
          config.user_id = user_id
          config.context = Bugsnag::Helpers.param_context(params) || Bugsnag::Helpers.request_context(request)
          
          config.meta_data ||= {}
          config.meta_data[:request] = {
            :url => request.url,
            :controller => params[:controller],
            :action => params[:action],
            :params => bugsnag_filter_if_filtering(env, Bugsnag::Helpers.cleanup_hash(params.to_hash)),
          }
          config.meta_data[:session] = bugsnag_filter_if_filtering(env, Bugsnag::Helpers.cleanup_hash(session))
          config.meta_data[:environment] = bugsnag_filter_if_filtering(env, Bugsnag::Helpers.cleanup_hash(env))
        end
      end

      private
      def bugsnag_filter_if_filtering(env, hash)
        @params_filters ||= env["action_dispatch.parameter_filter"]
        Bugsnag::Helpers.apply_filters(hash, @params_filters)
      end
    end
  end
end
