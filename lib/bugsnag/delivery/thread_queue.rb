require "thread"

module Bugsnag
  module Delivery
    class ThreadQueue < Synchronous
      MAX_OUTSTANDING_REQUESTS = 100
      STOP = Object.new


      class << self
        def deliver(url, body, configuration)
          if queue.length > MAX_OUTSTANDING_REQUESTS
            Bugsnag.warn("Dropping notification, #{queue.length} outstanding requests")
            return
          end

          # Add delivery to the worker thread
          queue.push proc { super(url, body, configuration) }
        end

        private

        attr_reader :queue

        def start!
          @queue = Queue.new

          worker_thread = Thread.new do
            while x = queue.pop
              break if x == STOP
              x.call
            end
          end

          at_exit do
            Bugsnag.warn("Waiting for #{queue.length} outstanding request(s)") unless queue.empty?
            queue.push STOP
            worker_thread.join
          end
        end
      end

      # do this once at require time to avoid race conditions
      start!
    end
  end
end

Bugsnag::Delivery.register(:thread_queue, Bugsnag::Delivery::ThreadQueue)
