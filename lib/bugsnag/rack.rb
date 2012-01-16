module Bugsnag
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        Bugsnag.auto_notify(raised, bugsnag_request_data(env))
        raise
      end

      if env['rack.exception']
        Bugsnag.auto_notify(env['rack.exception'], bugsnag_request_data(env))
      end

      response
    end
    
    private
    def bugsnag_request_data(env)
      request = ::Rack::Request.new(env)

      session = env['rack.session'] || {}
      params = env['action_dispatch.request.parameters'] || request.params || {}

      {
        :user_id => session[:session_id] || session["session_id"],
        :context => Bugsnag::Helpers.param_context(params),
        :meta_data => {
          :request => {
            :url => request.url,
            :controller => params[:controller],
            :action => params[:action],
            :params => bugsnag_filter_if_filtering(env, Bugsnag::Helpers.cleanup_hash(params.to_hash)),
          },
          :session => bugsnag_filter_if_filtering(env, Bugsnag::Helpers.cleanup_hash(session)),
          :environment => bugsnag_filter_if_filtering(env, Bugsnag::Helpers.cleanup_hash(env))
        }
      }
    end

    def bugsnag_filter_if_filtering(env, hash)
      @params_filters ||= env["action_dispatch.parameter_filter"]
      Bugsnag::Helpers.apply_filters(hash, @params_filters)
    end
  end
end
