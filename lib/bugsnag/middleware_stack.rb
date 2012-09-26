module Bugsnag
  class MiddlewareStack
    def initialize
      @middlewares = []
    end
  
    def use(new_middleware)
      @middlewares << new_middleware
    end
  
    def insert_after(after, new_middleware)
      index = (@middlewares.rindex(after) + 1)
      if index >= @middlewares.length
        @middlewares << new_middleware
      else
        @middlewares.insert index, new_middleware
      end
    end
  
    def insert_before(before, new_middleware)
      index = @middlewares.index(before) || @middlewares.length
      @middlewares.insert index, new_middleware
    end
    
    # This allows people to proxy methods to the array if they want to do more complex stuff
    def method_missing(method, *args, &block)
      @middlewares.send(method, *args, &block)
    end
    
    # Runs the middleware stack and calls 
    def run(exception, notification)
      request_data = Bugsnag.configuration.request_data

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
      @middlewares.map{|middleware| proc { |next_middleware| middleware.new(next_middleware) } }
    end
  end
end