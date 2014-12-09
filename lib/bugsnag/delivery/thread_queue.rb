require "thread"

module Bugsnag
  module Delivery
    class ThreadQueue < Synchronous
      MAX_OUTSTANDING_REQUESTS = 100
      STOP = Object.new

      class << self
        def deliver(url, body)
          if queue.length > MAX_OUTSTANDING_REQUESTS
            Bugsnag.warn("Dropping notification, #{queue.length} outstanding requests")
            return
          end

          # Add delivery to the worker thread
          queue.push proc { super }

          # Make sure the worker thread is started
          ensure_worker_thread_started
        end

        private
        def queue
          @queue ||= Queue.new
        end

        def ensure_worker_thread_started
          unless @worker_thread
            @worker_thread = Thread.new do
              while x = queue.pop
                break if x == STOP
                x.call
              end
            end

            at_exit do
              Bugsnag.warn("Waiting for #{queue.length} outstanding request(s)") unless queue.empty?
              queue.push STOP
              @worker_thread.join
            end
          end

          @worker_thread
        end
      end
    end
  end
end

Bugsnag::Delivery.register(:thread_queue, Bugsnag::Delivery::ThreadQueue)
