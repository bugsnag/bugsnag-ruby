module Bugsnag
  class Rack

    FRAMEWORK_ATTRIBUTES = {
      :framework => "Rack"
    }

    def initialize(app)
      @app = app

      # Configure bugsnag rack defaults
      Bugsnag.configure do |config|
        # Try to set the release_stage automatically if it hasn't already been set
        config.release_stage ||= ENV["RACK_ENV"] if ENV["RACK_ENV"]

        # Try to set the project_root if it hasn't already been set, or show a warning if we can't
        unless config.project_root && !config.project_root.to_s.empty?
          if defined?(settings)
            config.project_root = settings.root
          else
            config.warn("You should set your app's project_root (see https://bugsnag.com/docs/notifiers/ruby#project_root).")
          end
        end

        # Hook up rack-based notification middlewares
        config.middleware.insert_before([Bugsnag::Middleware::Rails3Request,Bugsnag::Middleware::Callbacks], Bugsnag::Middleware::RackRequest) if defined?(::Rack)
        config.middleware.insert_before(Bugsnag::Middleware::Callbacks, Bugsnag::Middleware::WardenUser) if defined?(Warden)
        config.middleware.insert_before(Bugsnag::Middleware::Callbacks, Bugsnag::Middleware::ClearanceUser) if defined?(Clearance)

        config.app_type ||= "rack"
      end
    end

    def call(env)
      # Set the request data for bugsnag middleware to use
      Bugsnag.configuration.set_request_data(:rack_env, env)

      begin
        response = @app.call(env)
      rescue Exception => raised
        # Notify bugsnag of rack exceptions
        Bugsnag.notify(raised, true) do |report|
          report.severity = "error"
          report.severity_reason = {
            :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
            :attributes => Bugsnag::Rack::FRAMEWORK_ATTRIBUTES
          }
        end

        # Re-raise the exception
        raise
      end

      # Notify bugsnag of rack exceptions
      if env["rack.exception"]
        Bugsnag.notify(env["rack.exception"], true) do |report|
          report.severity = "error"
          report.severity_reason = {
            :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
            :attributes => FRAMEWORK_ATTRIBUTES
          }
        end
      end

      response
    ensure
      # Clear per-request data after processing the each request
      Bugsnag.configuration.clear_request_data
    end
  end
end
