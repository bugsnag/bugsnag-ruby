module Bugsnag
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        Bugsnag.notify(raised)
        raise
      end

      if env["rack.exception"]
        Bugsnag.notify(env["rack.exception"])
      end

      response
    end
  end
end