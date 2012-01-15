module Bugsnag
  # Middleware for Rack applications. Any errors raised by the upstream
  # application will be delivered to Airbrake and re-raised.
  #
  # Synopsis:
  #
  #   require 'rack'
  #   require 'airbrake'
  #
  #   Airbrake.configure do |config|
  #     config.api_key = 'my_api_key'
  #   end
  #
  #   app = Rack::Builder.app do
  #     use Airbrake::Rack
  #     run lambda { |env| raise "Rack down" }
  #   end
  #
  # Use a standard Airbrake.configure call to configure your api key.
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        error_id = Bugsnag.notify(raised, bugsnag_request_data(env))
        raise
      end

      if env['rack.exception']
        error_id = Bugsnag.notify(env['rack.exception'], bugsnag_request_data(env))
      end

      response
    end
    
    private
    def bugsnag_request_data(env)
      request = ::Rack::Request.new(env)

      session = env['rack.session'] || {}
      params = env['action_dispatch.request.parameters'] || request.params || {}

      {
        :userId => session[:session_id] || session["session_id"],
        :context => "#{params[:controller]}##{params[:action]}",
        :metaData => {
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
