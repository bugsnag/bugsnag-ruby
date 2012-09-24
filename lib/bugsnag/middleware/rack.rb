module Bugsnag
  class Rack
    def initialize(app)
      @app = app

      # Automatically set the release_stage
      Bugsnag.configuration.release_stage = ENV['RACK_ENV'] if ENV['RACK_ENV']

      # Automatically set the project_root if possible
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
      # Automatically set any params_filters from the rack env (once only)
      unless @rack_filters
        @rack_filters = env["action_dispatch.parameter_filter"]
        Bugsnag.configuration.params_filters += @rack_filters
      end
      
      Bugsnag.set_request_data :rack_env, env

      begin
        response = @app.call(env)
      rescue Exception => raised
        # Notify bugsnag of rack exceptions
        Bugsnag.auto_notify(raised)

        # Re-raise the exception
        raise
      end

      # Notify bugsnag of rack exceptions
      if env["rack.exception"]
        Bugsnag.auto_notify(env["rack.exception"])
      end
        
      response
    ensure
      # Clear per-request data after processing the each request
      Bugsnag.clear_request_data
    end
  end
end
