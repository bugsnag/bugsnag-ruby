require "bugsnag/middleware/bugsnag/rack_request"

module Bugsnag
  class MiddlewareConfiguration
    class << self
      @@middleware = [
        Bugsnag::Middleware::RackRequest,
        Bugsnag::Middleware::RackEnvironment,
        Bugsnag::Middleware::RackSession,
      ]
  
      def use(new_middleware)
        @@middleware << new_middleware
      end
  
      def insert_after(after, new_middleware)
        index = (@middleware.rindex(after) + 1)
        if index >= @middleware.length
          @@middleware << new_middleware
        else
          @@middleware.insert index, new_middleware
        end
      end
  
      def insert_before(before, new_middleware)
        index = @@middleware.index(before) || @@middleware.length
        @@middleware.insert index, new_middleware
      end
    
      # This allows people to proxy methods to the array if they want to do more complex stuff
      def method_missing(method, *args, &block)
        @@middleware.send(method, *args, &block)
      end
    
      # Runs the middleware stack and calls 
      def run(request_data, exception, notification)
        # The final lambda is the termination of the middleware stack. It calls deliver on the notification
        #TODO:SM Deliver should be what it calls, but we should rename the other deliver
        lambda_has_run = false
        final_lambda = lambda {|request_data, exception, notification| lambda_has_run = true; notification.send}
      
        begin
          # We reverse them, so we can call "call" on the first middleware
          middleware_procs.reverse.inject(final_lambda) { |n,e| e[n] }.call(request_data, exception, notification)
        rescue Exception => e
          # We dont notify, as we dont want to loop forever in the case of really broken middleware, we will
          # still send this notify
          # TODO:SM We could send a notify for this, just skipping the middleware
          Bugsnag.warn "Bugsnag middleware error: #{e}"
          puts e.backtrace.inspect
        end
      
        # Ensure that the deliver has been performed, and no middleware has botched it
        unless lambda_has_run
          final_lambda.call(request_data, exception, notification)
        end
      end

      private
      # Generates a list of middleware procs that are ready to be run
      # Pass each one a reference to the next in the queue
      def middleware_procs
        @@middleware.map{|middleware| proc { |next_middleware| middleware.new(next_middleware) } }
      end
    end
  end
end